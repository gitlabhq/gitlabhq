module AppearancesHelper
  def brand_title
    if brand_item
      brand_item.title
    else
      'GitLab Enterprise Edition'
    end
  end

  def brand_image
    logo = if brand_item
             brand_item.logo
           else
             'brand_logo.png'
           end

    image_tag logo
  end

  def brand_text
    default_text =<<eos
### GitLab is open source software to collaborate on code.

Manage git repositories with fine grained access controls that keep your code secure.
Perform code reviews and enhance collaboration with merge requests.
Each project can also have an issue tracker and a wiki.

Used by more than 50,000 organizations, GitLab is the most popular solution to manage git repositories on-premises.
Read more about GitLab at #{link_to "www.gitlab.com", "https://www.gitlab.com/", target: "_blank"}.
eos


    text = if brand_item
             brand_item.description
           else
             default_text
           end

    markdown text
  end

  def brand_item
    @appearance ||= Appearance.first
  end
end
