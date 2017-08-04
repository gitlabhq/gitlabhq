module EE
  module Model
    def table_name_prefix
      'ee_'
    end

    def model_name
      @model_name ||= ActiveModel::Name.new(self, nil, self.name.demodulize)
    end
  end
end
