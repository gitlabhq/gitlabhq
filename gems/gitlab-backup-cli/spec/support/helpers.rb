# frozen_string_literal: true

def spec_path
  Pathname.new(__dir__).join('..').expand_path
end

def temp_path
  spec_path.join('..', 'tmp').expand_path
end

def stub_env(var, return_value)
  stub_const('ENV', ENV.to_hash.merge(var => return_value))
end
