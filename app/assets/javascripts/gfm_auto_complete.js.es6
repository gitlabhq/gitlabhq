/* eslint-disable */
// Creates the variables for setting up GFM auto-completion
(function() {
  if (window.GitLab == null) {
    window.GitLab = {};
  }

  GitLab.GfmAutoComplete = {
    dataLoading: false,
    dataLoaded: false,
    cachedData: {},
    dataSource: '',
    // Emoji
    Emoji: {
      template: '<li>${name} <img alt="${name}" height="20" src="${path}" width="20" /></li>'
    },
    // Team Members
    Members: {
      template: '<li>${avatarTag} ${username} <small>${title}</small></li>'
    },
    Labels: {
      template: '<li><span class="dropdown-label-box" style="background: ${color}"></span> ${title}</li>'
    },
    // Issues and MergeRequests
    Issues: {
      template: '<li><small>${id}</small> ${title}</li>'
    },
    // Milestones
    Milestones: {
      template: '<li>${title}</li>'
    },
    Loading: {
      template: '<li><i class="fa fa-refresh fa-spin"></i> Loading...</li>'
    },
    DefaultOptions: {
      sorter: function(query, items, searchKey) {
        // Highlight first item only if at least one char was typed
        this.setting.highlightFirst = this.setting.alwaysHighlightFirst || query.length > 0;
        if ((items[0].name != null) && items[0].name === 'loading') {
          return items;
        }
        return $.fn.atwho["default"].callbacks.sorter(query, items, searchKey);
      },
      filter: function(query, data, searchKey) {
        if (data[0] === 'loading') {
          return data;
        }
        return $.fn.atwho["default"].callbacks.filter(query, data, searchKey);
      },
      beforeInsert: function(value) {
        if (!GitLab.GfmAutoComplete.dataLoaded) {
          return this.at;
        } else {
          if (value.indexOf("unlabel") !== -1) {
            GitLab.GfmAutoComplete.input.atwho('load', '~', GitLab.GfmAutoComplete.cachedData.unlabels);
          } else {
            GitLab.GfmAutoComplete.input.atwho('load', '~', GitLab.GfmAutoComplete.cachedData.labels);
          }
          return value;
        }
      }
    },
    setup: _.debounce(function(input) {
      // Add GFM auto-completion to all input fields, that accept GFM input.
      this.input = input || $('.js-gfm-input');
      // destroy previous instances
      this.destroyAtWho();
      // set up instances
      this.setupAtWho();

      if (this.dataSource && !this.dataLoading && !this.cachedData) {
        this.dataLoading = true;
        return this.fetchData(this.dataSource)
          .done((data) => {
            this.dataLoading = false;
            this.loadData(data);
          });
        };

      if (this.cachedData != null) {
        return this.loadData(this.cachedData);
      }
    }, 1000),
    setupAtWho: function() {
      // Emoji
      this.input.atwho({
        at: ':',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.path != null) {
              return _this.Emoji.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        insertTpl: ':${name}:',
        data: ['loading'],
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert
        }
      });
      // Team Members
      this.input.atwho({
        at: '@',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.username != null) {
              return _this.Members.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        insertTpl: '${atwho-at}${username}',
        searchKey: 'search',
        data: ['loading'],
        alwaysHighlightFirst: true,
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
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
                avatarTag: autoCompleteAvatar.length === 1 ?  txtAvatar : imgAvatar,
                title: gl.utils.sanitize(title),
                search: gl.utils.sanitize(m.username + " " + m.name)
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '#',
        alias: 'issues',
        searchKey: 'search',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.title != null) {
              return _this.Issues.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        data: ['loading'],
        insertTpl: '${atwho-at}${id}',
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          beforeSave: function(issues) {
            return $.map(issues, function(i) {
              if (i.title == null) {
                return i;
              }
              return {
                id: i.iid,
                title: gl.utils.sanitize(i.title),
                search: i.iid + " " + i.title
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '%',
        alias: 'milestones',
        searchKey: 'search',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.title != null) {
              return _this.Milestones.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        insertTpl: '${atwho-at}"${title}"',
        data: ['loading'],
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          beforeSave: function(milestones) {
            return $.map(milestones, function(m) {
              if (m.title == null) {
                return m;
              }
              return {
                id: m.iid,
                title: gl.utils.sanitize(m.title),
                search: "" + m.title
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '!',
        alias: 'mergerequests',
        searchKey: 'search',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.title != null) {
              return _this.Issues.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        data: ['loading'],
        insertTpl: '${atwho-at}${id}',
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          beforeSave: function(merges) {
            return $.map(merges, function(m) {
              if (m.title == null) {
                return m;
              }
              return {
                id: m.iid,
                title: gl.utils.sanitize(m.title),
                search: m.iid + " " + m.title
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '~',
        alias: 'labels',
        searchKey: 'search',
        displayTpl: this.Labels.template,
        insertTpl: '${atwho-at}${title}',
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          beforeSave: function(merges) {
            var sanitizeLabelTitle;
            sanitizeLabelTitle = function(title) {
              if (/[\w\?&]+\s+[\w\?&]+/g.test(title)) {
                return "\"" + (gl.utils.sanitize(title)) + "\"";
              } else {
                return gl.utils.sanitize(title);
              }
            };
            return $.map(merges, function(m) {
              return {
                title: sanitizeLabelTitle(m.title),
                color: m.color,
                search: "" + m.title
              };
            });
          }
        }
      });
      // We don't instantiate the slash commands autocomplete for note and issue/MR edit forms
      this.input.filter('[data-supports-slash-commands="true"]').atwho({
        at: '/',
        alias: 'commands',
        searchKey: 'search',
        displayTpl: function(value) {
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
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          beforeSave: function(commands) {
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
            var regexp = /(?:^|\n)\/([A-Za-z_]*)$/gi
            var match = regexp.exec(subtext);
            if (match) {
              return match[1];
            } else {
              return null;
            }
          }
        }
      });
      return;
    },
    destroyAtWho: function() {
      return this.input.atwho('destroy');
    },
    fetchData: function(dataSource) {
      return $.getJSON(dataSource);
    },
    loadData: function(data) {
      this.cachedData = data;
      this.dataLoaded = true;
      // load members
      this.input.atwho('load', '@', data.members);
      // load issues
      this.input.atwho('load', 'issues', data.issues);
      // load milestones
      this.input.atwho('load', 'milestones', data.milestones);
      // load merge requests
      this.input.atwho('load', 'mergerequests', data.mergerequests);
      // load emojis
      this.input.atwho('load', ':', data.emojis);
      // load labels
      this.input.atwho('load', '~', data.labels);
      // load commands
      this.input.atwho('load', '/', data.commands);
      // This trigger at.js again
      // otherwise we would be stuck with loading until the user types
      return $(':focus').trigger('keyup');
    }
  };

}).call(this);
