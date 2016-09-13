String.instance_eval
  def expand_variables(variables)
    # Convert hash array to variables
    if variables.is_a?(Array)
      variables = variables.reduce({}) do |hash, variable|
        hash[variable[:key]] = variable[:value]
        hash
      end
    end

    self.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) do
      variables[$1 || $2]
    end
  end
end
