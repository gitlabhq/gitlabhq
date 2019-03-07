# frozen_string_literal: true

module Projects
  # Used by project imports, it removes any potential paths
  # included in an error message that could be stored in the DB
  class ImportErrorFilter
    ERROR_MESSAGE_FILTER = /[^\s]*#{File::SEPARATOR}[^\s]*(?=(\s|\z))/
    FILTER_MESSAGE = '[FILTERED]'

    def self.filter_message(message)
      message.gsub(ERROR_MESSAGE_FILTER, FILTER_MESSAGE)
    end
  end
end
