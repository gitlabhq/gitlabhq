require 'grit'
require 'pygments'
require 'linguist'

Grit::Blob.class_eval { include Linguist::BlobHelper }
