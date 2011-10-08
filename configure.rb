root_path = File.expand_path(File.dirname(__FILE__))
require File.join(root_path, "install", "prepare")
env = ARGV[0] || "development"

Install.prepare(env)
