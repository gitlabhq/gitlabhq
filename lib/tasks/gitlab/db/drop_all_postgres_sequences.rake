namespace :gitlab do
  namespace :db do
    task drop_all_postgres_sequences: :environment do
      connection = ActiveRecord::Base.connection
      connection.execute("SELECT c.relname FROM pg_class c WHERE c.relkind = 'S';").each do |sequence|
        connection.execute("DROP SEQUENCE #{sequence['relname']}")
      end
    end
  end
end
