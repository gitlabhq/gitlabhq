# frozen_string_literal: true

module ClickHouse
  class DictionaryCredentialsHandler
    # Replace references to the database name within the QUERY setting to $DICTIONARY_DATABASE.
    # Reason: tables in the dictionary query MUST have explicit database references
    # Additionally, replace settings:
    # USER -> $DICTIONARY_USER
    # PASSWORD -> $DICTIONARY_PASSWORD
    # SECURE -> $DICTIONARY_SECURE
    def self.replace_credentials_with_variables(database_name, schema)
      regex = /(QUERY\s+')((?:[^']|'')*)(')/

      schema = schema.gsub(regex) do
        prefix  = ::Regexp.last_match(1) # "QUERY '"
        content = ::Regexp.last_match(2) # "SELECT ... FROM database.table_name ..."
        suffix  = ::Regexp.last_match(3) # "'"

        new_content = content.gsub(database_name, '$DICTIONARY_DATABASE')

        "#{prefix}#{new_content}#{suffix}"
      end

      schema = schema.gsub(/USER\s+'.*?'/, "USER '$DICTIONARY_USER'")
      schema = schema.gsub(/PASSWORD\s+'.*?'/, "PASSWORD '$DICTIONARY_PASSWORD'")
      schema.gsub(/SECURE\s+'.*?'/, "SECURE '$DICTIONARY_SECURE'")
    end

    def self.replace_variables_with_credentials(database_config, statement)
      statement = statement.gsub("$DICTIONARY_USER", database_config.instance_variable_get(:@username))
      password = database_config.instance_variable_get(:@password).to_s.gsub("'", "''")
      statement = statement.gsub("$DICTIONARY_PASSWORD", password)
      statement = statement.gsub("$DICTIONARY_DATABASE", database_config.instance_variable_get(:@database))
      secure = database_config.instance_variable_get(:@url).start_with?('https')
      statement.gsub("$DICTIONARY_SECURE", secure ? '1' : '0')
    end
  end
end
