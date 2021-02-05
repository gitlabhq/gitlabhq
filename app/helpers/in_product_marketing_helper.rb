# frozen_string_literal: true

module InProductMarketingHelper
  def subject_line(track, series)
    {
      create: [
        s_('InProductMarketing|Create a project in GitLab in 5 minutes'),
        s_('InProductMarketing|Import your project and code from GitHub, Bitbucket and others'),
        s_('InProductMarketing|Understand repository mirroring')
      ],
      verify: [
        s_('InProductMarketing|Feel the need for speed?'),
        s_('InProductMarketing|3 ways to dive into GitLab CI/CD'),
        s_('InProductMarketing|Explore the power of GitLab CI/CD')
      ],
      trial: [
        s_('InProductMarketing|Go farther with GitLab'),
        s_('InProductMarketing|Automated security scans directly within GitLab'),
        s_('InProductMarketing|Take your source code management to the next level')
      ],
      team: [
        s_('InProductMarketing|Working in GitLab = more efficient'),
        s_("InProductMarketing|Multiple owners, confusing workstreams? We've got you covered"),
        s_('InProductMarketing|Your teams can be more efficient')
      ]
    }[track][series]
  end

  def in_product_marketing_logo(track, series)
    inline_image_link('mailers/in_product_marketing', "#{track}-#{series}.png", width: '150')
  end

  def about_link(folder, image, width)
    link_to inline_image_link(folder, image, { width: width, alt: s_('InProductMarketing|go to about.gitlab.com') }), 'https://about.gitlab.com/'
  end

  def in_product_marketing_tagline(track, series)
    {
      create: [
        s_('InProductMarketing|Get started today'),
        s_('InProductMarketing|Get our import guides'),
        s_('InProductMarketing|Need an alternative to importing?')
      ],
      verify: [
        s_('InProductMarketing|Use GitLab CI/CD'),
        s_('InProductMarketing|Test, create, deploy'),
        s_('InProductMarketing|Are your runners ready?')
      ],
      trial: [
        s_('InProductMarketing|Start a free trial of GitLab Gold – no CC required'),
        s_('InProductMarketing|Improve app security with a 30-day trial'),
        s_('InProductMarketing|Start with a GitLab Gold free trial')
      ],
      team: [
        s_('InProductMarketing|Invite your colleagues to join in less than one minute'),
        s_('InProductMarketing|Get your team set up on GitLab'),
        nil
      ]
    }[track][series]
  end

  def in_product_marketing_title(track, series)
    {
      create: [
        s_('InProductMarketing|Take your first steps with GitLab'),
        s_('InProductMarketing|Start by importing your projects'),
        s_('InProductMarketing|How (and why) mirroring makes sense')
      ],
      verify: [
        s_('InProductMarketing|Rapid development, simplified'),
        s_('InProductMarketing|Get started with GitLab CI/CD'),
        s_('InProductMarketing|Launch GitLab CI/CD in 20 minutes or less')
      ],
      trial: [
        s_('InProductMarketing|Give us one minute...'),
        s_("InProductMarketing|Security that's integrated into your development lifecycle"),
        s_('InProductMarketing|Improve code quality and streamline reviews')
      ],
      team: [
        s_('InProductMarketing|Team work makes the dream work'),
        s_('InProductMarketing|*GitLab*, noun: a synonym for efficient teams'),
        s_('InProductMarketing|Find out how your teams are really doing')
      ]
    }[track][series]
  end

  def in_product_marketing_subtitle(track, series)
    {
      create: [
        s_('InProductMarketing|Dig in and create a project and a repo'),
        s_("InProductMarketing|Here's what you need to know"),
        s_('InProductMarketing|Try it out')
      ],
      verify: [
        s_('InProductMarketing|How to build and test faster'),
        s_('InProductMarketing|Explore the options'),
        s_('InProductMarketing|Follow our steps')
      ],
      trial: [
        s_('InProductMarketing|...and you can get a free trial of GitLab Gold'),
        s_('InProductMarketing|Try GitLab Gold for free'),
        s_('InProductMarketing|Better code in less time')
      ],
      team: [
        s_('InProductMarketing|Actually, GitLab makes the team work (better)'),
        s_('InProductMarketing|Our tool brings all the things together'),
        s_("InProductMarketing|It's all in the stats")
      ]
    }[track][series]
  end

  def in_product_marketing_body_line1(track, series, format: nil)
    {
      create: [
        s_("InProductMarketing|To understand and get the most out of GitLab, start at the beginning and %{project_link}. In GitLab, repositories are part of a project, so after you've created your project you can go ahead and %{repo_link}.") % { project_link: project_link(format), repo_link: repo_link(format) },
        s_("InProductMarketing|Making the switch? It's easier than you think to import your projects into GitLab. Move %{github_link}, or import something %{bitbucket_link}.") % { github_link: github_link(format), bitbucket_link: bitbucket_link(format) },
        s_("InProductMarketing|Sometimes you're not ready to make a full transition to a new tool. If you're not ready to fully commit, %{mirroring_link} gives you a safe way to try out GitLab in parallel with your current tool.") % { mirroring_link: mirroring_link(format) }
      ],
      verify: [
        s_("InProductMarketing|Tired of wrestling with disparate tool chains, information silos and inefficient processes? GitLab's CI/CD is built on a DevOps platform with source code management, planning, monitoring and more ready to go. Find out %{ci_link}.") % { ci_link: ci_link(format) },
        s_("InProductMarketing|GitLab's CI/CD makes software development easier. Don't believe us? Here are three ways you can take it for a fast (and satisfying) test drive:"),
        s_("InProductMarketing|Get going with CI/CD quickly using our %{quick_start_link}. Start with an available runner and then create a CI .yml file – it's really that easy.") % { quick_start_link: quick_start_link(format) }
      ],
      trial: [
        [
          s_("InProductMarketing|GitLab's premium tiers are designed to make you, your team and your application more efficient and more secure with features including but not limited to:"),
          list([
            s_('InProductMarketing|%{strong_start}Company wide portfolio management%{strong_end} — including multi-level epics, scoped labels').html_safe % strong_options(format),
            s_('InProductMarketing|%{strong_start}Multiple approval roles%{strong_end} — including code owners and required merge approvals').html_safe % strong_options(format),
            s_('InProductMarketing|%{strong_start}Advanced application security%{strong_end} — including SAST, DAST scanning, FUZZ testing, dependency scanning, license compliance, secrete detection').html_safe % strong_options(format),
            s_('InProductMarketing|%{strong_start}Executive level insights%{strong_end} — including reporting on productivity, tasks by type, days to completion, value stream').html_safe % strong_options(format)
          ], format)
        ].join("\n"),
        s_('InProductMarketing|GitLab provides static application security testing (SAST), dynamic application security testing (DAST), container scanning, and dependency scanning to help you deliver secure applications along with license compliance.'),
        s_('InProductMarketing|By enabling code owners and required merge approvals the right person will review the right MR. This is a win-win: cleaner code and a more efficient review process.')
      ],
      team: [
        [
          s_('InProductMarketing|Did you know teams that use GitLab are far more efficient?'),
          list([
            s_('InProductMarketing|Goldman Sachs went from 1 build every two weeks to thousands of builds a day'),
            s_('InProductMarketing|Ticketmaster decreased their CI build time by 15X')
          ], format)
        ].join("\n"),
        s_("InProductMarketing|We know a thing or two about efficiency and we don't want to keep that to ourselves. Sign up for a free trial of GitLab Gold and your teams will be on it from day one."),
        [
          s_('InProductMarketing|Stop wondering and use GitLab to answer questions like:'),
          list([
            s_('InProductMarketing|How long does it take us to close issues/MRs by types like feature requests, bugs, tech debt, security?'),
            s_('InProductMarketing|How many days does it take our team to complete various tasks?'),
            s_('InProductMarketing|What does our value stream timeline look like from product to development to review and production?')
          ], format)
        ].join("\n")
      ]
    }[track][series]
  end

  def in_product_marketing_body_line2(track, series, format: nil)
    {
      create: [
        s_("InProductMarketing|That's all it takes to get going with GitLab, but if you're new to working with Git, check out our %{basics_link} for helpful tips and tricks for getting started.") % { basics_link: basics_link(format) },
        s_("InProductMarketing|Have a different instance you'd like to import? Here's our %{import_link}.") % { import_link: import_link(format) },
        s_("InProductMarketing|It's also possible to simply %{external_repo_link} in order to take advantage of GitLab's CI/CD.") % { external_repo_link: external_repo_link(format) }
      ],
      verify: [
        nil,
        list([
          s_('InProductMarketing|Start by %{performance_link}').html_safe % { performance_link: performance_link(format) },
          s_('InProductMarketing|Move on to easily creating a Pages website %{ci_template_link}').html_safe % { ci_template_link: ci_template_link(format) },
          s_('InProductMarketing|And finally %{deploy_link} a Python application.').html_safe % { deploy_link: deploy_link(format) }
        ], format),
        nil
      ],
      trial: [
        s_('InProductMarketing|Start a GitLab Gold trial today in less than one minute, no credit card required.'),
        s_('InProductMarketing|Get started today with a 30-day GitLab Gold trial, no credit card required.'),
        s_('InProductMarketing|Code owners and required merge approvals are part of the paid tiers of GitLab. You can start a free 30-day trial of GitLab Gold and enable these features in less than 5 minutes with no credit card required.')
      ],
      team: [
        s_('InProductMarketing|Invite your colleagues and start shipping code faster.'),
        s_("InProductMarketing|Streamline code review, know at a glance who's unavailable, communicate in comments or in email and integrate with Slack so everyone's on the same page."),
        s_('InProductMarketing|When your team is on GitLab these answers are a click away.')
      ]
    }[track][series]
  end

  def cta_link(track, series, group, format: nil)
    case format
    when :html
      link_to in_product_marketing_cta_text(track, series), group_email_campaigns_url(group, track: track, series: series), target: '_blank', rel: 'noopener noreferrer'
    else
      [in_product_marketing_cta_text(track, series), group_email_campaigns_url(group, track: track, series: series)].join(' >> ')
    end
  end

  def in_product_marketing_progress(track, series)
    s_('InProductMarketing|This is email %{series} of 3 in the %{track} series.') % { series: series + 1, track: track.to_s.humanize }
  end

  def footer_links(format: nil)
    links = [
      [s_('InProductMarketing|Blog'), 'https://about.gitlab.com/blog'],
      [s_('InProductMarketing|Twitter'), 'https://twitter.com/gitlab'],
      [s_('InProductMarketing|Facebook'), 'https://www.facebook.com/gitlab'],
      [s_('InProductMarketing|YouTube'), 'https://www.youtube.com/channel/UCnMGQ8QHMAnVIsI3xJrihhg']
    ]
    case format
    when :html
      links.map do |text, link|
        link_to(text, link)
      end
    else
      '| ' + links.map do |text, link|
        [text, link].join(' ')
      end.join("\n| ")
    end
  end

  def address(format: nil)
    s_('InProductMarketing|%{strong_start}GitLab Inc.%{strong_end} 268 Bush Street, #350, San Francisco, CA 94104, USA').html_safe % strong_options(format)
  end

  def unsubscribe(format: nil)
    parts = [
      s_('InProductMarketing|If you no longer wish to receive marketing emails from us,'),
      s_('InProductMarketing|you may %{unsubscribe_link} at any time.') % { unsubscribe_link: unsubscribe_link(format) }
    ]
    case format
    when :html
      parts.join(' ')
    else
      parts.join("\n" + ' ' * 16)
    end
  end

  private

  def in_product_marketing_cta_text(track, series)
    {
      create: [
        s_('InProductMarketing|Create your first project!'),
        s_('InProductMarketing|Master the art of importing!'),
        s_('InProductMarketing|Understand your project options')
      ],
      verify: [
        s_('InProductMarketing|Get to know GitLab CI/CD'),
        s_('InProductMarketing|Try it yourself'),
        s_('InProductMarketing|Explore GitLab CI/CD')
      ],
      trial: [
        s_('InProductMarketing|Start a trial'),
        s_('InProductMarketing|Beef up your security'),
        s_('InProductMarketing|Go for the gold!')
      ],
      team: [
        s_('InProductMarketing|Invite your colleagues today'),
        s_('InProductMarketing|Invite your team in less than 60 seconds'),
        s_('InProductMarketing|Invite your team now')
      ]
    }[track][series]
  end

  def project_link(format)
    link(s_('InProductMarketing|create a project'), help_page_url('gitlab-basics/create-project'), format)
  end

  def repo_link(format)
    link(s_('InProductMarketing|set up a repo'), help_page_url('user/project/repository/index', anchor: 'create-a-repository'), format)
  end

  def github_link(format)
    link(s_('InProductMarketing|GitHub Enterprise projects to GitLab'), help_page_url('integration/github'), format)
  end

  def bitbucket_link(format)
    link(s_('InProductMarketing|from Bitbucket'), help_page_url('user/project/import/bitbucket_server'), format)
  end

  def mirroring_link(format)
    link(s_('InProductMarketing|repository mirroring'), help_page_url('user/project/repository/repository_mirroring'), format)
  end

  def ci_link(format)
    link(s_('InProductMarketing|how easy it is to get started'), help_page_url('ci/README'), format)
  end

  def performance_link(format)
    link(s_('InProductMarketing|testing browser performance'), help_page_url('user/project/merge_requests/browser_performance_testing'), format)
  end

  def ci_template_link(format)
    link(s_('InProductMarketing|using a CI/CD template'), help_page_url('user/project/pages/getting_started/pages_ci_cd_template'), format)
  end

  def deploy_link(format)
    link(s_('InProductMarketing|test and deploy'), help_page_url('ci/examples/test-and-deploy-python-application-to-heroku'), format)
  end

  def quick_start_link(format)
    link(s_('InProductMarketing|quick start guide'), help_page_url('ci/quick_start/README'), format)
  end

  def basics_link(format)
    link(s_('InProductMarketing|Git basics'), help_page_url('gitlab-basics/README'), format)
  end

  def import_link(format)
    link(s_('InProductMarketing|comprehensive guide'), help_page_url('user/project/import/index'), format)
  end

  def external_repo_link(format)
    link(s_('InProductMarketing|connect an external repository'), new_project_url(anchor: 'cicd_for_external_repo'), format)
  end

  def unsubscribe_link(format)
    link(s_('InProductMarketing|unsubscribe'), '%tag_unsubscribe_url%', format)
  end

  def link(text, link, format)
    case format
    when :html
      link_to text, link
    else
      "#{text} (#{link})"
    end
  end

  def list(array, format)
    case format
    when :html
      tag.ul { array.map { |item| concat tag.li item} }
    else
      '- ' + array.join("\n- ")
    end
  end

  def strong_options(format)
    case format
    when :html
      { strong_start: '<b>'.html_safe, strong_end: '</b>'.html_safe }
    else
      { strong_start: '', strong_end: '' }
    end
  end

  def inline_image_link(folder, image, **options)
    attachments[image] = File.read(Rails.root.join("app/assets/images", folder, image))
    image_tag attachments[image].url, **options
  end
end
