import $ from 'jquery';
import 'at.js';
import _ from 'underscore';
import glRegexp from './lib/utils/regexp';
import AjaxCache from './lib/utils/ajax_cache';
import { spriteIcon } from './lib/utils/common_utils';

function sanitize(str) {
  return str.replace(/<(?:.|\n)*?>/gm, '');
}

export function membersBeforeSave(members) {
  return _.map(members, member => {
    const GROUP_TYPE = 'Group';

    let title = '';
    if (member.username == null) {
      return member;
    }
    title = member.name;
    if (member.count && !member.mentionsDisabled) {
      title += ` (${member.count})`;
    }

    const autoCompleteAvatar = member.avatar_url || member.username.charAt(0).toUpperCase();

    const rectAvatarClass = member.type === GROUP_TYPE ? 'rect-avatar' : '';
    const imgAvatar = `<img src="${member.avatar_url}" alt="${member.username}" class="avatar ${rectAvatarClass} avatar-inline center s26"/>`;
    const txtAvatar = `<div class="avatar ${rectAvatarClass} center avatar-inline s26">${autoCompleteAvatar}</div>`;
    const avatarIcon = member.mentionsDisabled
      ? spriteIcon('notifications-off', 's16 vertical-align-middle prepend-left-5')
      : '';

    return {
      username: member.username,
      avatarTag: autoCompleteAvatar.length === 1 ? txtAvatar : imgAvatar,
      title: sanitize(title),
      search: sanitize(`${member.username} ${member.name}`),
      icon: avatarIcon,
    };
  });
}

export const defaultAutocompleteConfig = {
  emojis: true,
  members: true,
  issues: true,
  mergeRequests: true,
  epics: true,
  milestones: true,
  labels: true,
  snippets: true,
};

class GfmAutoComplete {
  constructor(dataSources) {
    this.dataSources = dataSources || {};
    this.cachedData = {};
    this.isLoadingData = {};
  }

  setup(input, enableMap = defaultAutocompleteConfig) {
    // Add GFM auto-completion to all input fields, that accept GFM input.
    this.input = input || $('.js-gfm-input');
    this.enableMap = enableMap;
    this.setupLifecycle();
  }

  setupLifecycle() {
    this.input.each((i, input) => {
      const $input = $(input);
      $input.off('focus.setupAtWho').on('focus.setupAtWho', this.setupAtWho.bind(this, $input));
      $input.on('change.atwho', () => input.dispatchEvent(new Event('input')));
      // This triggers at.js again
      // Needed for quick actions with suffixes (ex: /label ~)
      $input.on('inserted-commands.atwho', $input.trigger.bind($input, 'keyup'));
      $input.on('clear-commands-cache.atwho', () => this.clearCache());
    });
  }

  setupAtWho($input) {
    if (this.enableMap.emojis) this.setupEmoji($input);
    if (this.enableMap.members) this.setupMembers($input);
    if (this.enableMap.issues) this.setupIssues($input);
    if (this.enableMap.milestones) this.setupMilestones($input);
    if (this.enableMap.mergeRequests) this.setupMergeRequests($input);
    if (this.enableMap.labels) this.setupLabels($input);
    if (this.enableMap.snippets) this.setupSnippets($input);

    // We don't instantiate the quick actions autocomplete for note and issue/MR edit forms
    $input.filter('[data-supports-quick-actions="true"]').atwho({
      at: '/',
      alias: 'commands',
      searchKey: 'search',
      skipSpecialCharacterTest: true,
      skipMarkdownCharacterTest: true,
      data: GfmAutoComplete.defaultLoadingData,
      displayTpl(value) {
        const cssClasses = [];

        if (GfmAutoComplete.isLoading(value)) return GfmAutoComplete.Loading.template;
        // eslint-disable-next-line no-template-curly-in-string
        let tpl = '<li class="<%- className %>"><span class="name">/${name}</span>';
        if (value.aliases.length > 0) {
          tpl += ' <small class="aliases">(or /<%- aliases.join(", /") %>)</small>';
        }
        if (value.params.length > 0) {
          tpl += ' <small class="params"><%- params.join(" ") %></small>';
        }
        if (value.description !== '') {
          tpl += '<small class="description"><i><%- description %> <%- warningText %></i></small>';
        }
        tpl += '</li>';

        if (value.warning) {
          cssClasses.push('has-warning');
        }

        return _.template(tpl)({
          ...value,
          className: cssClasses.join(' '),
          warningText: value.warning ? `(${value.warning})` : '',
        });
      },
      insertTpl(value) {
        // eslint-disable-next-line no-template-curly-in-string
        let tpl = '/${name} ';
        let referencePrefix = null;
        if (value.params.length > 0) {
          [[referencePrefix]] = value.params;
          if (/^[@%~]/.test(referencePrefix)) {
            tpl += '<%- referencePrefix %>';
          }
        }
        return _.template(tpl)({ referencePrefix });
      },
      suffix: '',
      callbacks: {
        ...this.getDefaultCallbacks(),
        beforeSave(commands) {
          if (GfmAutoComplete.isLoading(commands)) return commands;
          return $.map(commands, c => {
            let search = c.name;
            if (c.aliases.length > 0) {
              search = `${search} ${c.aliases.join(' ')}`;
            }
            return {
              name: c.name,
              aliases: c.aliases,
              params: c.params,
              description: c.description,
              warning: c.warning,
              search,
            };
          });
        },
        matcher(flag, subtext) {
          const regexp = /(?:^|\n)\/([A-Za-z_]*)$/gi;
          const match = regexp.exec(subtext);
          if (match) {
            return match[1];
          }
          return null;
        },
      },
    });
  }

  setupEmoji($input) {
    // Emoji
    $input.atwho({
      at: ':',
      displayTpl(value) {
        let tmpl = GfmAutoComplete.Loading.template;
        if (value && value.name) {
          tmpl = GfmAutoComplete.Emoji.templateFunction(value.name);
        }
        return tmpl;
      },
      // eslint-disable-next-line no-template-curly-in-string
      insertTpl: ':${name}:',
      skipSpecialCharacterTest: true,
      data: GfmAutoComplete.defaultLoadingData,
      callbacks: {
        ...this.getDefaultCallbacks(),
        matcher(flag, subtext) {
          const regexp = new RegExp(`(?:[^${glRegexp.unicodeLetters}0-9:]|\n|^):([^:]*)$`, 'gi');
          const match = regexp.exec(subtext);

          return match && match.length ? match[1] : null;
        },
      },
    });
  }

  setupMembers($input) {
    // Team Members
    $input.atwho({
      at: '@',
      alias: 'users',
      displayTpl(value) {
        let tmpl = GfmAutoComplete.Loading.template;
        const { avatarTag, username, title, icon } = value;
        if (username != null) {
          tmpl = GfmAutoComplete.Members.templateFunction({
            avatarTag,
            username,
            title,
            icon,
          });
        }
        return tmpl;
      },
      // eslint-disable-next-line no-template-curly-in-string
      insertTpl: '${atwho-at}${username}',
      searchKey: 'search',
      alwaysHighlightFirst: true,
      skipSpecialCharacterTest: true,
      data: GfmAutoComplete.defaultLoadingData,
      callbacks: {
        ...this.getDefaultCallbacks(),
        beforeSave: membersBeforeSave,
      },
    });
  }

  setupIssues($input) {
    $input.atwho({
      at: '#',
      alias: 'issues',
      searchKey: 'search',
      displayTpl(value) {
        let tmpl = GfmAutoComplete.Loading.template;
        if (value.title != null) {
          tmpl = GfmAutoComplete.Issues.templateFunction(value);
        }
        return tmpl;
      },
      data: GfmAutoComplete.defaultLoadingData,
      insertTpl: GfmAutoComplete.Issues.insertTemplateFunction,
      skipSpecialCharacterTest: true,
      callbacks: {
        ...this.getDefaultCallbacks(),
        beforeSave(issues) {
          return $.map(issues, i => {
            if (i.title == null) {
              return i;
            }
            return {
              id: i.iid,
              title: sanitize(i.title),
              reference: i.reference,
              search: `${i.iid} ${i.title}`,
            };
          });
        },
      },
    });
  }

  setupMilestones($input) {
    $input.atwho({
      at: '%',
      alias: 'milestones',
      searchKey: 'search',
      // eslint-disable-next-line no-template-curly-in-string
      insertTpl: '${atwho-at}${title}',
      displayTpl(value) {
        let tmpl = GfmAutoComplete.Loading.template;
        if (value.title != null) {
          tmpl = GfmAutoComplete.Milestones.templateFunction(value.title);
        }
        return tmpl;
      },
      data: GfmAutoComplete.defaultLoadingData,
      callbacks: {
        ...this.getDefaultCallbacks(),
        beforeSave(milestones) {
          return $.map(milestones, m => {
            if (m.title == null) {
              return m;
            }
            return {
              id: m.iid,
              title: sanitize(m.title),
              search: m.title,
            };
          });
        },
      },
    });
  }

  setupMergeRequests($input) {
    $input.atwho({
      at: '!',
      alias: 'mergerequests',
      searchKey: 'search',
      displayTpl(value) {
        let tmpl = GfmAutoComplete.Loading.template;
        if (value.title != null) {
          tmpl = GfmAutoComplete.Issues.templateFunction(value);
        }
        return tmpl;
      },
      data: GfmAutoComplete.defaultLoadingData,
      insertTpl: GfmAutoComplete.Issues.insertTemplateFunction,
      skipSpecialCharacterTest: true,
      callbacks: {
        ...this.getDefaultCallbacks(),
        beforeSave(merges) {
          return $.map(merges, m => {
            if (m.title == null) {
              return m;
            }
            return {
              id: m.iid,
              title: sanitize(m.title),
              reference: m.reference,
              search: `${m.iid} ${m.title}`,
            };
          });
        },
      },
    });
  }

  setupLabels($input) {
    const instance = this;
    const fetchData = this.fetchData.bind(this);
    const LABEL_COMMAND = { LABEL: '/label', UNLABEL: '/unlabel', RELABEL: '/relabel' };
    let command = '';

    $input.atwho({
      at: '~',
      alias: 'labels',
      searchKey: 'search',
      data: GfmAutoComplete.defaultLoadingData,
      displayTpl(value) {
        let tmpl = GfmAutoComplete.Labels.templateFunction(value.color, value.title);
        if (GfmAutoComplete.isLoading(value)) {
          tmpl = GfmAutoComplete.Loading.template;
        }
        return tmpl;
      },
      // eslint-disable-next-line no-template-curly-in-string
      insertTpl: '${atwho-at}${title}',
      limit: 20,
      callbacks: {
        ...this.getDefaultCallbacks(),
        beforeSave(merges) {
          if (GfmAutoComplete.isLoading(merges)) return merges;
          return $.map(merges, m => ({
            title: sanitize(m.title),
            color: m.color,
            search: m.title,
            set: m.set,
          }));
        },
        matcher(flag, subtext) {
          const subtextNodes = subtext
            .split(/\n+/g)
            .pop()
            .split(GfmAutoComplete.regexSubtext);

          // Check if ~ is followed by '/label', '/relabel' or '/unlabel' commands.
          command = subtextNodes.find(node => {
            if (
              node === LABEL_COMMAND.LABEL ||
              node === LABEL_COMMAND.RELABEL ||
              node === LABEL_COMMAND.UNLABEL
            ) {
              return node;
            }
            return null;
          });

          // If any label matches the inserted text after the last `~`, suggest those labels,
          // even if any spaces or funky characters were typed.
          // This allows matching labels like "Accepting merge requests".
          const labels = instance.cachedData[flag];
          if (labels) {
            if (!subtext.includes(flag)) {
              // Do not match if there is no `~` before the cursor
              return null;
            }
            const lastCandidate = subtext.split(flag).pop();
            if (labels.find(label => label.title.startsWith(lastCandidate))) {
              return lastCandidate;
            }
          } else {
            // Load all labels into the autocompleter.
            // This needs to happen if e.g. editing a label in an existing comment, because normally
            // label data would only be loaded only once you type `~`.
            fetchData(this.$inputor, this.at);
          }

          const match = GfmAutoComplete.defaultMatcher(flag, subtext, this.app.controllers);
          return match && match.length ? match[1] : null;
        },
        filter(query, data, searchKey) {
          if (GfmAutoComplete.isLoading(data)) {
            fetchData(this.$inputor, this.at);
            return data;
          }

          if (data === GfmAutoComplete.defaultLoadingData) {
            return $.fn.atwho.default.callbacks.filter(query, data, searchKey);
          }

          // The `LABEL_COMMAND.RELABEL` is intentionally skipped
          // because we want to return all the labels (unfiltered) for that command.
          if (command === LABEL_COMMAND.LABEL) {
            // Return labels with set: undefined.
            return data.filter(label => !label.set);
          } else if (command === LABEL_COMMAND.UNLABEL) {
            // Return labels with set: true.
            return data.filter(label => label.set);
          }

          return data;
        },
      },
    });
  }

  setupSnippets($input) {
    $input.atwho({
      at: '$',
      alias: 'snippets',
      searchKey: 'search',
      displayTpl(value) {
        let tmpl = GfmAutoComplete.Loading.template;
        if (value.title != null) {
          tmpl = GfmAutoComplete.Issues.templateFunction(value);
        }
        return tmpl;
      },
      data: GfmAutoComplete.defaultLoadingData,
      // eslint-disable-next-line no-template-curly-in-string
      insertTpl: '${atwho-at}${id}',
      callbacks: {
        ...this.getDefaultCallbacks(),
        beforeSave(snippets) {
          return $.map(snippets, m => {
            if (m.title == null) {
              return m;
            }
            return {
              id: m.id,
              title: sanitize(m.title),
              search: `${m.id} ${m.title}`,
            };
          });
        },
      },
    });
  }

  getDefaultCallbacks() {
    const fetchData = this.fetchData.bind(this);

    return {
      sorter(query, items, searchKey) {
        this.setting.highlightFirst = this.setting.alwaysHighlightFirst || query.length > 0;
        if (GfmAutoComplete.isLoading(items)) {
          this.setting.highlightFirst = false;
          return items;
        }
        return $.fn.atwho.default.callbacks.sorter(query, items, searchKey);
      },
      filter(query, data, searchKey) {
        if (GfmAutoComplete.isLoading(data)) {
          fetchData(this.$inputor, this.at);
          return data;
        }
        return $.fn.atwho.default.callbacks.filter(query, data, searchKey);
      },
      beforeInsert(value) {
        let withoutAt = value.substring(1);
        const at = value.charAt();

        if (value && !this.setting.skipSpecialCharacterTest) {
          const regex = at === '~' ? /\W|^\d+$/ : /\W/;
          if (withoutAt && regex.test(withoutAt)) {
            withoutAt = `"${withoutAt}"`;
          }
        }

        // We can ignore this for quick actions because they are processed
        // before Markdown.
        if (!this.setting.skipMarkdownCharacterTest) {
          withoutAt = withoutAt
            .replace(/(~~|`|\*)/g, '\\$1')
            .replace(/(\b)(_+)/g, '$1\\$2') // only escape underscores at the start
            .replace(/(_+)(\b)/g, '\\$1$2'); // or end of words
        }

        return `${at}${withoutAt}`;
      },
      matcher(flag, subtext) {
        const match = GfmAutoComplete.defaultMatcher(flag, subtext, this.app.controllers);

        if (match) {
          return match[1];
        }
        return null;
      },
      highlighter(li, query) {
        // override default behaviour to escape dot character
        // see https://github.com/ichord/At.js/pull/576
        if (!query) {
          return li;
        }
        const escapedQuery = query.replace(/[.+]/, '\\$&');
        const regexp = new RegExp(`>\\s*([^<]*?)(${escapedQuery})([^<]*)\\s*<`, 'ig');
        return li.replace(regexp, (str, $1, $2, $3) => `> ${$1}<strong>${$2}</strong>${$3} <`);
      },
    };
  }

  fetchData($input, at) {
    if (this.isLoadingData[at]) return;

    this.isLoadingData[at] = true;
    const dataSource = this.dataSources[GfmAutoComplete.atTypeMap[at]];

    if (this.cachedData[at]) {
      this.loadData($input, at, this.cachedData[at]);
    } else if (GfmAutoComplete.atTypeMap[at] === 'emojis') {
      import(/* webpackChunkName: 'emoji' */ './emoji')
        .then(({ validEmojiNames, glEmojiTag }) => {
          this.loadData($input, at, validEmojiNames);
          GfmAutoComplete.glEmojiTag = glEmojiTag;
        })
        .catch(() => {
          this.isLoadingData[at] = false;
        });
    } else if (dataSource) {
      AjaxCache.retrieve(dataSource, true)
        .then(data => {
          this.loadData($input, at, data);
        })
        .catch(() => {
          this.isLoadingData[at] = false;
        });
    } else {
      this.isLoadingData[at] = false;
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

  clearCache() {
    this.cachedData = {};
  }

  destroy() {
    this.input.each((i, input) => {
      const $input = $(input);
      $input.atwho('destroy');
    });
  }

  static isLoading(data) {
    let dataToInspect = data;
    if (data && data.length > 0) {
      [dataToInspect] = data;
    }

    const loadingState = GfmAutoComplete.defaultLoadingData[0];
    return dataToInspect && (dataToInspect === loadingState || dataToInspect.name === loadingState);
  }

  static defaultMatcher(flag, subtext, controllers) {
    // The below is taken from At.js source
    // Tweaked to commands to start without a space only if char before is a non-word character
    // https://github.com/ichord/At.js
    const atSymbolsWithBar = Object.keys(controllers)
      .join('|')
      .replace(/[$]/, '\\$&');
    const atSymbolsWithoutBar = Object.keys(controllers).join('');
    const targetSubtext = subtext.split(GfmAutoComplete.regexSubtext).pop();
    const resultantFlag = flag.replace(/[-[\]/{}()*+?.\\^$|]/g, '\\$&');

    const accentAChar = decodeURI('%C3%80');
    const accentYChar = decodeURI('%C3%BF');

    // Holy regex, batman!
    const regexp = new RegExp(
      `^(?:\\B|[^a-zA-Z0-9_\`${atSymbolsWithoutBar}]|\\s)${resultantFlag}(?!${atSymbolsWithBar})((?:[A-Za-z${accentAChar}-${accentYChar}0-9_'.+-:]|[^\\x00-\\x7a])*)$`,
      'gi',
    );

    return regexp.exec(targetSubtext);
  }
}

GfmAutoComplete.regexSubtext = new RegExp(/\s+/g);

GfmAutoComplete.defaultLoadingData = ['loading'];

GfmAutoComplete.atTypeMap = {
  ':': 'emojis',
  '@': 'members',
  '#': 'issues',
  '!': 'mergeRequests',
  '&': 'epics',
  '~': 'labels',
  '%': 'milestones',
  '/': 'commands',
  $: 'snippets',
};

// Emoji
GfmAutoComplete.glEmojiTag = null;
GfmAutoComplete.Emoji = {
  templateFunction(name) {
    // glEmojiTag helper is loaded on-demand in fetchData()
    if (GfmAutoComplete.glEmojiTag) {
      return `<li>${name} ${GfmAutoComplete.glEmojiTag(name)}</li>`;
    }
    return `<li>${name}</li>`;
  },
};
// Team Members
GfmAutoComplete.Members = {
  templateFunction({ avatarTag, username, title, icon }) {
    return `<li>${avatarTag} ${username} <small>${_.escape(title)}</small> ${icon}</li>`;
  },
};
GfmAutoComplete.Labels = {
  templateFunction(color, title) {
    return `<li><span class="dropdown-label-box" style="background: ${_.escape(
      color,
    )}"></span> ${_.escape(title)}</li>`;
  },
};
// Issues, MergeRequests and Snippets
GfmAutoComplete.Issues = {
  insertTemplateFunction(value) {
    // eslint-disable-next-line no-template-curly-in-string
    return value.reference || '${atwho-at}${id}';
  },
  templateFunction({ id, title, reference }) {
    return `<li><small>${reference || id}</small> ${_.escape(title)}</li>`;
  },
};
// Milestones
GfmAutoComplete.Milestones = {
  templateFunction(title) {
    return `<li>${_.escape(title)}</li>`;
  },
};
GfmAutoComplete.Loading = {
  template:
    '<li style="pointer-events: none;"><i class="fa fa-spinner fa-spin"></i> Loading...</li>',
};

export default GfmAutoComplete;
