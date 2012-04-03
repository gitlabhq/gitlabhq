class GitlabSerialize
  # Called to deserialize data to ruby object.
  def load(data)
    hash = parse_data(data)
    hash = HashWithIndifferentAccess.new(hash) if hash
    hash
  end

  def parse_data(data)
    JSON.load(data)
  rescue JSON::ParserError
    begin
      YAML.load(data)
    rescue Psych::SyntaxError
      nil
    end
  end

  # Called to convert from ruby object to serialized data.
  def dump(obj)
    JSON.dump(obj)
  end
end
