# frozen_string_literal: true

module BulkImports
  module FileTransfer
    extend self

    UnsupportedObjectType = Class.new(StandardError)

    def config_for(portable, offline: false)
      case portable
      when ::Project
        ::BulkImports::FileTransfer::ProjectConfig.new(portable, offline: offline)
      when ::Group
        ::BulkImports::FileTransfer::GroupConfig.new(portable, offline: offline)
      else
        raise(UnsupportedObjectType, "Unsupported object type: #{portable.class}")
      end
    end
  end
end
