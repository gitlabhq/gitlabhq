class ApplicationDecorator < Drapper::Base
  # Lazy Helpers
  #   PRO: Call Rails helpers without the h. proxy
  #        ex: number_to_currency(model.price)
  #   CON: Add a bazillion methods into your decorator's namespace
  #        and probably sacrifice performance/memory
  #  
  #   Enable them by uncommenting this line:
  #   lazy_helpers

  # Shared Decorations
  #   Consider defining shared methods common to all your models.
  #   
  #   Example: standardize the formatting of timestamps
  #
  #   def formatted_timestamp(time)
  #     h.content_tag :span, time.strftime("%a %m/%d/%y"), 
  #                   :class => 'timestamp' 
  #   end
  # 
  #   def created_at
  #     formatted_timestamp(model.created_at)
  #   end
  # 
  #   def updated_at
  #     formatted_timestamp(model.updated_at)
  #   end
end
