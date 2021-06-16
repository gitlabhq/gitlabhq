#!/usr/bin/env ruby
x = $stdin.read
File.write('/tmp/rb-data.txt', x)
