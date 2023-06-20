# frozen_string_literal: true

desc "Migrate the test results data from InfluxDB to GCS to visualise in Sisense/Tableau"
task :influx_to_gcs, [:range] do |_task, args|
  QA::Tools::MigrateInfluxDataToGcs.run(**args)
end
