# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/install/requirements.md#supported-webbrowsers
# Supported browsers:
#  - Chrome (Latest stable version)
#  - Firefox (Latest released version)
#  - Safari 7+ (known problem: required fields in html5 do not work)
#  - Opera (Latest released version)
#  - IE 10+
# 25.08.2014
Browser.modern_rules.clear
Browser.modern_rules << -> b { b.chrome?  && b.version >= '36' }
Browser.modern_rules << -> b { b.firefox? && b.version >= '31' }
Browser.modern_rules << -> b { b.safari?  && b.version >= '7'  }
Browser.modern_rules << -> b { b.opera?   && b.version >= '12' }
Browser.modern_rules << -> b { b.ie?      && b.version >= '10' }
