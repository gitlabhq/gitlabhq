# frozen_string_literal: true

# This script updates the `table_size:` in table dictionaries.
# The daily-database-table-size.json file can be found in
# https://gitlab.com/gitlab-com/gl-infra/platform/stage-groups-index.
#
# First introduced in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169064.
# Further improvements, including a different data source is planned in
# https://gitlab.com/gitlab-org/gitlab/-/issues/477398.
#
# The documentation about the limits can be found in doc/development/database/database_dictionary.md.

require "json"
require "yaml"

data_file = ARGV[0]

if data_file.nil?
  puts "Please supply data_file as first argument"
  puts "Ex: ruby scripts/database/table_sizes.rb <path to daily-database-table-size.json>"
  exit 1
end

puts "Reading #{data_file}..."

database_table_size =
  JSON.parse(File.read(data_file))
    .dig("database_table_size_daily", "body", "data", "result")
    .each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |metric, result|
      table_name, type = metric["metric"].values_at("relname", "type")
      result[table_name][type] ||= { count: 0, size: metric["value"].last.to_f }
      result[table_name][type][:count] += 1
    end

def list_of_partitioned_tables(object, database_table_size)
  if database_table_size[object].values.none?
    object = object.delete_prefix("p_") if object.start_with?("p_")

    database_table_size.select { |table_name| table_name =~ Regexp.new("#{object}_\\d+$") }
  else
    database_table_size.select { |table_name| table_name == object }
  end
end

def primary_sizes(object, database_table_size)
  objects = list_of_partitioned_tables(object, database_table_size)

  objects.each_with_object({}) do |(object, _), output|
    database_table_size[object].each_key do |key|
      next unless key == "patroni-ci" || key == "patroni"

      output[key] ||= 0
      output[key] += database_table_size[object][key][:size]
    end
  end
end

def primary_size(object, database_table_size)
  primary_sizes(object, database_table_size).values.sum
end

def size_in_gb(size_in_bytes)
  (size_in_bytes.to_f / (1024 * 1024 * 1024))
end

def possible_primary_table_name(possible_partitioned_table_name)
  possible_partitioned_table_name.sub(/_\d+$/, '')
end

def table_size_classification(size_in_gigabytes)
  if size_in_gigabytes < 10
    "small"
  elsif size_in_gigabytes < 50
    "medium"
  elsif size_in_gigabytes < 100
    "large"
  else
    "over_limit"
  end
end

sizes = database_table_size.keys.map do |object|
  primary_size_in_bytes = primary_size(object, database_table_size)
  [object, size_in_gb(primary_size_in_bytes)]
end.sort_by(&:last).reverse

sizes.sort_by(&:last).each do |table_name, size_gb|
  file = "db/docs/#{table_name}.yml"

  file = "db/docs/#{possible_primary_table_name(table_name)}.yml" unless File.exist?(file)

  next unless File.exist?(file)

  puts "Updating file #{file}"

  data = YAML.safe_load(File.read(file))
  data["table_size"] = table_size_classification(size_gb)

  File.open(file, 'w+') { |f| f.write(data.to_yaml) }
end

[10, 50, 100, 999999].each_cons(2) do |(lower_threshold, upper_threshold)|
  tables = sizes.select do |_o, size_in_gb|
    size_in_gb >= lower_threshold && size_in_gb < upper_threshold
  end

  puts "Tables exceeding #{lower_threshold} GB: #{tables.count}"
end
