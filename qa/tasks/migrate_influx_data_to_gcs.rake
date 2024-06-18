# frozen_string_literal: true

desc "Migrate the test results data from InfluxDB to GCS in csv format"
task :influx_to_gcs_csv, [:hours] do |_task, args|
  QA::Tools::MigrateInfluxDataToGcsCsv.run(**args)
end

desc "Migrate the test results data from InfluxDB to GCS in json format"
task :influx_to_gcs_json, [:year, :month, :day] do |_, args|
  QA::Tools::MigrateInfluxDataToGcsJson.run(**args)
end
