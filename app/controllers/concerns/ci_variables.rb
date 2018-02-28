module CiVariables
  extend ActiveSupport::Concern

  def filtered_variables_params
    params = variables_params
    params['variables_attributes'].group_by { |var| [var['key'], var['environment_scope']] }.each_value do |variables|
      if variables.count > 1
        variable = variables.find { |var| var['_destroy'] == 'true' }
        next unless variable

        params['variables_attributes'].delete(variable)
        params['variables_attributes'].find(variable.merge('id' => '', '_destroy' => '')).each { |var| var['id'] = variable['id'] }
      end
    end
    params
  end
end
