/* eslint-disable func-names, space-before-function-paren, no-template-curly-in-string, comma-dangle, object-shorthand, quotes, dot-notation, no-else-return, one-var, no-var, no-underscore-dangle, one-var-declaration-per-line, no-param-reassign, no-useless-escape, prefer-template, consistent-return, wrap-iife, prefer-arrow-callback, camelcase, no-unused-vars, no-useless-return, vars-on-top, max-len */

import emojiMap from 'emojis/digests.json';
import emojiAliases from 'emojis/aliases.json';
import { glEmojiTag } from '~/behaviors/gl_emoji';

function sanitize(str) {
  return str.replace(/<(?:.|\n)*?>/gm, '');
}

class GfmAutoComplete {
  constructor(dataSources) {
    this.dataSources = dataSources || {};
    this.cachedData = {};
    this.isLoadingData = {};
  }

  setup(input) {
    // Add GFM auto-completion to all input fields, that accept GFM input.
    this.input = $(input) || $('.js-gfm-input');
    this.setupLifecycle();
  }

  setupLifecycle() {
    this.input.each((i, input) => {
      const $input = $(input);
      $input.off('focus.setupAtWho').on('focus.setupAtWho', this.setupAtWho.bind(this, $input));
      // This triggers at.js again
      // Needed for slash commands with suffixes (ex: /label ~)
      $input.on('inserted-commands.atwho', $input.trigger.bind($input, 'keyup'));
    });
  }

  setupAtWho($input) {
    this.setupEmoji($input);
    this.setupMembers($input);
    this.setupIssues($input);
    this.setupMilestones($input);
    this.setupMergeRequests($input);
    this.setupLabels($input);

    const fetchData = this.fetchData.bind(this);
    // We don't instantiate the slash commands autocomplete for note and issue/MR edit forms
    $input.filter('[data-supports-slash-commands="true"]').atwho({
      at: '/',
      alias: 'commands',
      searchKey: 'search',
      skipSpecialCharacterTest: true,
      data: GfmAutoComplete.defaultLoadingData,
      displayTpl(value) {
        if (GfmAutoComplete.isLoading(value)) return GfmAutoComplete.Loading.template;
        var tpl = '<li>/${name}';
        if (value.aliases.length > 0) {
          tpl += ' <small>(or /<%- aliases.join(", /") %>)</small>';
        }
        if (value.params.length > 0) {
          tpl += ' <small><%- params.join(" ") %></small>';
        }
        if (value.description !== '') {
          tpl += '<small class="description"><i><%- description %></i></small>';
        }
        tpl += '</li>';
        return _.template(tpl)(value);
      },
      insertTpl: function(value) {
        var tpl = "/${name} ";
        var reference_prefix = null;
        if (value.params.length > 0) {
          reference_prefix = value.params[0][0];
          if (/^[@%~]/.test(reference_prefix)) {
            tpl += '<%- reference_prefix %>';
          }
        }
        return _.template(tpl)({ reference_prefix: reference_prefix });
      },
      suffix: '',
      callbacks: {
        sorter: GfmAutoComplete.DefaultOptions.sorter,
        filter(...args) {
          return GfmAutoComplete.DefaultOptions.filter.bind(this)(fetchData, ...args);
        },
        beforeInsert: GfmAutoComplete.DefaultOptions.beforeInsert,
        beforeSave(commands) {
          if (GfmAutoComplete.isLoading(commands)) return commands;
          return $.map(commands, function(c) {
            var search = c.name;
            if (c.aliases.length > 0) {
              search = search + " " + c.aliases.join(" ");
            }
            return {
              name: c.name,
              aliases: c.aliases,
              params: c.params,
              description: c.description,
              search: search
            };
          });
        },
        matcher: function(flag, subtext, should_startWithSpace, acceptSpaceBar) {
          var regexp = /(?:^|\n)\/([A-Za-z_]*)$/gi;
          var match = regexp.exec(subtext);
          if (match) {
            return match[1];
          } else {
            return null;
          }
        }
      }
    });
  }

  setupEmoji($input) {
    const fetchData = this.fetchData.bind(this);
    // Emoji
    $input.atwho({
      at: ':',
      displayTpl(value) {
        return value && value.name ? GfmAutoComplete.Emoji.templateFunction(value.name) : GfmAutoComplete.Loading.template;
      },
      insertTpl: ':${name}:',
      skipSpecialCharacterTest: true,
      data: GfmAutoComplete.defaultLoadingData,
      callbacks: {
        sorter: GfmAutoComplete.DefaultOptions.sorter,
        beforeInsert: GfmAutoComplete.DefaultOptions.beforeInsert,
        filter(...args) {
          return GfmAutoComplete.DefaultOptions.filter.bind(this)(fetchData, ...args);
        },
      }
    });
  }

  setupMembers($input) {
    const fetchData = this.fetchData.bind(this);
    // Team Members
    $input.atwho({
      at: '@',
      displayTpl(value) {
        return value.username != null ? GfmAutoComplete.Members.template : GfmAutoComplete.Loading.template;
      },
      insertTpl: '${atwho-at}${username}',
      searchKey: 'search',
      alwaysHighlightFirst: true,
      skipSpecialCharacterTest: true,
      data: GfmAutoComplete.defaultLoadingData,
      callbacks: {
        sorter: GfmAutoComplete.DefaultOptions.sorter,
        filter(...args) {
          return GfmAutoComplete.DefaultOptions.filter.bind(this)(fetchData, ...args);
        },
        beforeInsert: GfmAutoComplete.DefaultOptions.beforeInsert,
        matcher: GfmAutoComplete.DefaultOptions.matcher,
        beforeSave: function(members) {
          return $.map(members, function(m) {
            let title = '';
            if (m.username == null) {
              return m;
            }
            title = m.name;
            if (m.count) {
              title += " (" + m.count + ")";
            }

            const autoCompleteAvatar = m.avatar_url || m.username.charAt(0).toUpperCase();
            const imgAvatar = `<img src="${m.avatar_url}" alt="${m.username}" class="avatar avatar-inline center s26"/>`;
            const txtAvatar = `<div class="avatar center avatar-inline s26">${autoCompleteAvatar}</div>`;

            return {
              username: m.username,
              avatarTag: autoCompleteAvatar.length === 1 ? txtAvatar : imgAvatar,
              title: sanitize(title),
              search: sanitize(m.username + " " + m.name)
            };
          });
        }
      }
    });
  }

  setupIssues($input) {
    const fetchData = this.fetchData.bind(this);
    $input.atwho({
      at: '#',
      alias: 'issues',
      searchKey: 'search',
      displayTpl(value) {
        return value.title != null ? GfmAutoComplete.Issues.template : GfmAutoComplete.Loading.template;
      },
      data: GfmAutoComplete.defaultLoadingData,
      insertTpl: '${atwho-at}${id}',
      callbacks: {
        sorter: GfmAutoComplete.DefaultOptions.sorter,
        filter(...args) {
          return GfmAutoComplete.DefaultOptions.filter.bind(this)(fetchData, ...args);
        },
        beforeInsert: GfmAutoComplete.DefaultOptions.beforeInsert,
        matcher: GfmAutoComplete.DefaultOptions.matcher,
        beforeSave: function(issues) {
          return $.map(issues, function(i) {
            if (i.title == null) {
              return i;
            }
            return {
              id: i.iid,
              title: sanitize(i.title),
              search: i.iid + " " + i.title
            };
          });
        }
      }
    });
  }

  setupMilestones($input) {
    const fetchData = this.fetchData.bind(this);
    $input.atwho({
      at: '%',
      alias: 'milestones',
      searchKey: 'search',
      insertTpl: '${atwho-at}${title}',
      displayTpl(value) {
        return value.title != null ? GfmAutoComplete.Milestones.template : GfmAutoComplete.Loading.template;
      },
      data: GfmAutoComplete.defaultLoadingData,
      callbacks: {
        matcher: GfmAutoComplete.DefaultOptions.matcher,
        sorter: GfmAutoComplete.DefaultOptions.sorter,
        beforeInsert: GfmAutoComplete.DefaultOptions.beforeInsert,
        filter(...args) {
          return GfmAutoComplete.DefaultOptions.filter.bind(this)(fetchData, ...args);
        },
        beforeSave: function(milestones) {
          return $.map(milestones, function(m) {
            if (m.title == null) {
              return m;
            }
            return {
              id: m.iid,
              title: sanitize(m.title),
              search: "" + m.title
            };
          });
        }
      }
    });
  }

  setupMergeRequests($input) {
    const fetchData = this.fetchData.bind(this);
    $input.atwho({
      at: '!',
      alias: 'mergerequests',
      searchKey: 'search',
      displayTpl(value) {
        return value.title != null ? GfmAutoComplete.Issues.template : GfmAutoComplete.Loading.template;
      },
      data: GfmAutoComplete.defaultLoadingData,
      insertTpl: '${atwho-at}${id}',
      callbacks: {
        sorter: GfmAutoComplete.DefaultOptions.sorter,
        filter(...args) {
          return GfmAutoComplete.DefaultOptions.filter.bind(this)(fetchData, ...args);
        },
        beforeInsert: GfmAutoComplete.DefaultOptions.beforeInsert,
        matcher: GfmAutoComplete.DefaultOptions.matcher,
        beforeSave: function(merges) {
          return $.map(merges, function(m) {
            if (m.title == null) {
              return m;
            }
            return {
              id: m.iid,
              title: sanitize(m.title),
              search: m.iid + " " + m.title
            };
          });
        }
      }
    });
  }

  setupLabels($input) {
    const fetchData = this.fetchData.bind(this);
    $input.atwho({
      at: '~',
      alias: 'labels',
      searchKey: 'search',
      data: GfmAutoComplete.defaultLoadingData,
      displayTpl(value) {
        return GfmAutoComplete.isLoading(value) ? GfmAutoComplete.Loading.template : GfmAutoComplete.Labels.template;
      },
      insertTpl: '${atwho-at}${title}',
      callbacks: {
        matcher: GfmAutoComplete.DefaultOptions.matcher,
        beforeInsert: GfmAutoComplete.DefaultOptions.beforeInsert,
        filter(...args) {
          return GfmAutoComplete.DefaultOptions.filter.bind(this)(fetchData, ...args);
        },
        sorter: GfmAutoComplete.DefaultOptions.sorter,
        beforeSave(merges) {
          if (GfmAutoComplete.isLoading(merges)) return merges;
          var sanitizeLabelTitle;
          sanitizeLabelTitle = function(title) {
            if (/[\w\?&]+\s+[\w\?&]+/g.test(title)) {
              return "\"" + (sanitize(title)) + "\"";
            } else {
              return sanitize(title);
            }
          };
          return $.map(merges, function(m) {
            return {
              title: sanitize(m.title),
              color: m.color,
              search: "" + m.title
            };
          });
        },
      }
    });
  }

  fetchData($input, at) {
    if (this.isLoadingData[at]) return;
    this.isLoadingData[at] = true;
    if (this.cachedData[at]) {
      this.loadData($input, at, this.cachedData[at]);
    } else if (GfmAutoComplete.atTypeMap[at] === 'emojis') {
      this.loadData($input, at, Object.keys(emojiMap).concat(Object.keys(emojiAliases)));
    } else {
      $.getJSON(this.dataSources[GfmAutoComplete.atTypeMap[at]], (data) => {
        this.loadData($input, at, data);
      }).fail(() => { this.isLoadingData[at] = false; });
    }
  }
  loadData($input, at, data) {
    this.isLoadingData[at] = false;
    this.cachedData[at] = data;
    $input.atwho('load', at, data);
    // This trigger at.js again
    // otherwise we would be stuck with loading until the user types
    return $input.trigger('keyup');
  }

  static isLoading(data) {
    var dataToInspect = data;
    if (data && data.length > 0) {
      dataToInspect = data[0];
    }

    var loadingState = GfmAutoComplete.defaultLoadingData[0];
    return dataToInspect &&
      (dataToInspect === loadingState || dataToInspect.name === loadingState);
  }
}

GfmAutoComplete.defaultLoadingData = ['loading'];

GfmAutoComplete.DefaultOptions = {
  sorter(query, items, searchKey) {
    this.setting.highlightFirst = this.setting.alwaysHighlightFirst || query.length > 0;
    if (GfmAutoComplete.isLoading(items)) {
      this.setting.highlightFirst = false;
      return items;
    }
    return $.fn.atwho["default"].callbacks.sorter(query, items, searchKey);
  },
  filter(fetchData, query, data, searchKey) {
    if (GfmAutoComplete.isLoading(data)) {
      fetchData(this.$inputor, this.at);
      return data;
    } else {
      return $.fn.atwho["default"].callbacks.filter(query, data, searchKey);
    }
  },
  beforeInsert(value) {
    if (value && !this.setting.skipSpecialCharacterTest) {
      var withoutAt = value.substring(1);
      if (withoutAt && /[^\w\d]/.test(withoutAt)) value = value.charAt() + '"' + withoutAt + '"';
    }
    return value;
  },
  matcher(flag, subtext) {
    // The below is taken from At.js source
    // Tweaked to commands to start without a space only if char before is a non-word character
    // https://github.com/ichord/At.js
    var _a, _y, regexp, match, atSymbolsWithBar, atSymbolsWithoutBar;
    atSymbolsWithBar = Object.keys(this.app.controllers).join('|');
    atSymbolsWithoutBar = Object.keys(this.app.controllers).join('');
    subtext = subtext.split(/\s+/g).pop();
    flag = flag.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");

    _a = decodeURI("%C3%80");
    _y = decodeURI("%C3%BF");

    regexp = new RegExp("^(?:\\B|[^a-zA-Z0-9_" + atSymbolsWithoutBar + "]|\\s)" + flag + "(?!" + atSymbolsWithBar + ")((?:[A-Za-z" + _a + "-" + _y + "0-9_\'\.\+\-]|[^\\x00-\\x7a])*)$", 'gi');

    match = regexp.exec(subtext);

    if (match) {
      return match[1];
    } else {
      return null;
    }
  }
};

GfmAutoComplete.atTypeMap = {
  ':': 'emojis',
  '@': 'members',
  '#': 'issues',
  '!': 'mergeRequests',
  '~': 'labels',
  '%': 'milestones',
  '/': 'commands'
};

// Emoji
GfmAutoComplete.Emoji = {
  templateFunction: function(name) {
    return `<li>
      ${name} ${glEmojiTag(name)}
    </li>
    `;
  }
};
// Team Members
GfmAutoComplete.Members = {
  template: '<li>${avatarTag} ${username} <small>${title}</small></li>'
};
GfmAutoComplete.Labels = {
  template: '<li><span class="dropdown-label-box" style="background: ${color}"></span> ${title}</li>'
};
// Issues and MergeRequests
GfmAutoComplete.Issues = {
  template: '<li><small>${id}</small> ${title}</li>'
};
// Milestones
GfmAutoComplete.Milestones = {
  template: '<li>${title}</li>'
};
GfmAutoComplete.Loading = {
  template: '<li style="pointer-events: none;"><i class="fa fa-spinner fa-spin"></i> Loading...</li>'
};

export default GfmAutoComplete;
