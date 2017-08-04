module EE
  module LegacyModel
    def table_name_prefix
      ''
    end

    def model_name
      @model_name ||= ActiveModel::Name.new(self, nil, self.name.demodulize)
    end
  end
end
