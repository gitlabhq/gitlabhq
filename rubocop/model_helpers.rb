module RuboCop
  module ModelHelpers
    # Returns true if the given node originated from the models directory.
    def in_model?(node)
      path = node.location.expression.source_buffer.name
      models_path = File.join(Dir.pwd, 'app', 'models')

      path.start_with?(models_path)
    end
  end
end
