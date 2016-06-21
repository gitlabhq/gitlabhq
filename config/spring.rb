Dir.glob(File.join('config', '*.yml')).each do |file|
  Spring.watch file
end
