module Utils
  def self.binary?(string) 
    string.each_byte do |x|
      x.nonzero? or return true 
    end
    false
  end
end
