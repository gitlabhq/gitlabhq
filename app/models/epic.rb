# Placeholder class for model that is implemented in EE
# It will reserve (ee#3853) '&' as a reference prefix, but the table does not exists in CE
class Epic < ActiveRecord::Base
  # TODO: this will be implemented as part of #3853
  def to_reference
  end
end
