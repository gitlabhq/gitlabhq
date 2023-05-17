# frozen_string_literal: true

module BulkImports
  module FileTransfer
    extend self

    UnsupportedObjectType = Class.new(StandardError)

    def config_for(portable)
      case portable
      when ::Project
        ::BulkImports::FileTransfer::ProjectConfig.new(portable)
      when ::Group
        ::BulkImports::FileTransfer::GroupConfig.new(portable)
      else
        raise(UnsupportedObjectType, "Unsupported object type: #{portable.class}")
      end
    end
  end
end
