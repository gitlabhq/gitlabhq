namespace :gitlab do
  namespace :db do
    task drop_all_tables: :environment do
      connection = ActiveRecord::Base.connection
      connection.tables.each do |table|
        connection.drop_table(table)
      end
    end
  end
end
