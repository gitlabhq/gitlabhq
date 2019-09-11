desc 'Show a list of obsolete `ignored_columns`'
task 'db:obsolete_ignored_columns' => :environment do
  list = Gitlab::Database::ObsoleteIgnoredColumns.new.execute

  if list.empty?
    puts 'No obsolete `ignored_columns` found.'
  else
    puts 'The following `ignored_columns` are obsolete and can be removed:'

    list.each do |name, ignored_columns|
      puts "- #{name}: #{ignored_columns.join(', ')}"
    end

    puts <<~TEXT

      WARNING: Removing columns is tricky because running GitLab processes may still be using the columns.

      See also https://docs.gitlab.com/ee/development/what_requires_downtime.html#dropping-columns
    TEXT
  end
end
