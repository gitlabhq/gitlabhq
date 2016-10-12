// Creates the variables for setting up GFM auto-completion
(() => {
  if (window.GitLab == null) {
    window.GitLab = {};
  }

  class GfmInputor {
    constructor(elem) {
      this.gfm = GitLab.GfmAutoComplete;
      this.elem = $(elem);
      this.setup();
    }

    setup() {
      this.destroyAtWho();
      this.setupAtWho();
      this.loadData();
    }

    setupAtWho() {
     // Emoji
      this.elem.atwho({
        at: ':',
        displayTpl: (value) => {
          if (value.path != null) {
            return this.gfm.Emoji.template;
          } else {
            return this.gfm.Loading.template;
          }
        },
        insertTpl: ':${name}:',
        data: ['loading'],
        callbacks: {
          sorter: this.gfm.DefaultOptions.sorter,
          filter: this.gfm.DefaultOptions.filter,
          beforeInsert: this.gfm.DefaultOptions.beforeInsert
        }
      });
      // Team Members
      this.elem.atwho({
        at: '@',
        displayTpl: (value) => {
          if (value.username != null) {
            return this.gfm.Members.template;
          } else {
            return this.gfm.Loading.template;
          }
        },
        insertTpl: '${atwho-at}${username}',
        searchKey: 'search',
        data: ['loading'],
        callbacks: {
          sorter: this.gfm.DefaultOptions.sorter,
          filter: this.gfm.DefaultOptions.filter,
          beforeInsert: this.gfm.DefaultOptions.beforeInsert,
          beforeSave: (members) => {
            return $.map(members, (m) => {
              var title;
              if (m.username == null) {
                return m;
              }
              title = m.name;
              if (m.count) {
                title += " (" + m.count + ")";
              }
              return {
                username: m.username,
                title: sanitize(title),
                search: sanitize(m.username + " " + m.name)
              };
            });
          }
        }
      });
      this.elem.atwho({
        at: '#',
        alias: 'issues',
        searchKey: 'search',
        displayTpl: (value) => {
          if (value.title != null) {
            return this.gfm.Issues.template;
          } else {
            return this.gfm.Loading.template;
          }
        },
        data: ['loading'],
        insertTpl: '${atwho-at}${id}',
        callbacks: {
          sorter: this.gfm.DefaultOptions.sorter,
          filter: this.gfm.DefaultOptions.filter,
          beforeInsert: this.gfm.DefaultOptions.beforeInsert,
          beforeSave: (issues) => {
            return $.map(issues, (i) => {
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
      this.elem.atwho({
        at: '%',
        alias: 'milestones',
        searchKey: 'search',
        displayTpl: (value) => {
          if (value.title != null) {
            return this.gfm.Milestones.template;
          } else {
            return this.gfm.Loading.template;
          }
        },
        insertTpl: '${atwho-at}"${title}"',
        data: ['loading'],
        callbacks: {
          beforeSave: (milestones) => {
            return $.map(milestones, (m) => {
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
      this.elem.atwho({
        at: '!',
        alias: 'mergerequests',
        searchKey: 'search',
        displayTpl: (value) => {
          if (value.title != null) {
            return this.gfm.Issues.template;
          } else {
            return this.gfm.Loading.template;
          }
        },
        data: ['loading'],
        insertTpl: '${atwho-at}${id}',
        callbacks: {
          sorter: this.gfm.DefaultOptions.sorter,
          filter: this.gfm.DefaultOptions.filter,
          beforeInsert: this.gfm.DefaultOptions.beforeInsert,
          beforeSave: (merges) => {
            return $.map(merges, (m) => {
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
      this.elem.atwho({
        at: '~',
        alias: 'labels',
        searchKey: 'search',
        displayTpl: this.gfm.Labels.template,
        insertTpl: '${atwho-at}${title}',
        callbacks: {
          beforeSave: (merges) => {
            var sanitizeLabelTitle;
            sanitizeLabelTitle = (title) => {
              if (/[\w\?&]+\s+[\w\?&]+/g.test(title)) {
                return "\"" + (sanitize(title)) + "\"";
              } else {
                return sanitize(title);
              }
            };
            return $.map(merges, (m) => {
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
      // Can't filter elem tho
      this.elem.filter('[data-supports-slash-commands="true"]').atwho({
        at: '/',
        alias: 'commands',
        searchKey: 'search',
        displayTpl: (value) => {
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
        insertTpl: (value) => {
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
          sorter: this.gfm.DefaultOptions.sorter,
          filter: this.gfm.DefaultOptions.filter,
          beforeInsert: this.gfm.DefaultOptions.beforeInsert,
          beforeSave: (commands) => {
            return $.map(commands, (c) => {
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
          matcher: (flag, subtext, should_startWithSpace, acceptSpaceBar) => {
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
    }
    // inputtor
    destroyAtWho() {
      return this.elem.atwho('destroy');
    }

    loadData() {
      const data = this.gfm.cachedData;
      // load members
      this.elem.atwho('load', '@', data.members);
      // load issues
      this.elem.atwho('load', 'issues', data.issues);
      // load milestones
      this.elem.atwho('load', 'milestones', data.milestones);
      // load merge requests
      this.elem.atwho('load', 'mergerequests', data.mergerequests);
      // load emojis
      this.elem.atwho('load', ':', data.emojis);
      // load labels
      this.elem.atwho('load', '~', data.labels);
      // load commands
      this.elem.atwho('load', '/', data.commands);
      // This trigger at.js again
      // otherwise we would be stuck with loading until the user types
      return $(':focus').trigger('keyup');
    }
  }

/* Implementation of Gfm Pub/Sub

  function myMatcher(val) {
    return val.indexOf('hello') > -1;
  }

  function myCallback(val) {
    console.log(val);
  }

  GitLab.GfmAutoComplete.subscribe(myMatcher, myCallback);

*/
let GfmAutoComplete;

  class GfmFactory {
    constructor() {
      if (!GfmAutoComplete) {
        GfmAutoComplete = this;
        GfmAutoComplete.init();
      }
      return GfmAutoComplete;
    }

    init() {
      // TODO: at this point, don't need to keep track of inputors. Reconsider storing.
      this.inputors = [];
      this.subscribers = [];
      this.dataLoading = false;
      this.dataLoaded = false;
      this.cachedData = {};
      this.dataSource = '';
      this.listenForAddSuccess();

      this.Emoji = {
        template: '<li>${name} <img alt="${name}" height="20" src="${path}" width="20" /></li>'
      };

      this.Members = {
        template: '<li>${username} <small>${title}</small></li>'
      };

      this.Labels = {
        template: '<li><span class="dropdown-label-box" style="background: ${color}"></span> ${title}</li>'
      };

      this.Issues = {
        template: '<li><small>${id}</small> ${title}</li>'
      };

      this.Milestones = {
        template: '<li>${title}</li>'
      };

      this.Loading = {
        template: '<li><i class="fa fa-refresh fa-spin"></i> Loading...</li>'
      };

      this.DefaultOptions = {
        sorter: function(query, items, searchKey) {
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
            return value;
          }
        }
      };
    }

    listenForAddSuccess() {
      $(document).on('ajax:success', '.gfm-form', this.publish.bind(this));
    }

    subscribe(matcher, callback) {
      // TODO: Store by resource key -- this will depend on how Luke breaks things up
      this.subscribers.push({ matcher, callback });
    }

    publish(event) {
      const target = $(event.currentTarget).find('textarea');
      const targetInputor = this.inputors.filter((inputor) => {
        return inputor.elem.attr('data-noteable-iid') == target.attr('data-noteable-iid');
      })[0];
      const inputorText = targetInputor.elem.val();
      // after submit event
      const matched  = this.subscribers.filter((subscriber) => {
        const matcher = subscriber.matcher;
        // matcher must return boolean
        return matcher(inputorText);
      });
      matched.forEach((subscriber) => {
        subscriber.callback(inputorText);
      });
    }

    initInputors() {
      $('.js-gfm-input').each((i, inputor) => {
        const inputorModel = new GfmInputor(inputor);
        this.inputors.push(inputorModel);
      });
    }

    setup() {
      if (this.dataSource && !this.dataLoading && !this.cachedData) {
        this.dataLoading = true;
        return this.fetchData(this.dataSource)
          .done((data) => {
            // TODO: Make this DRY
            this.cachedData = data;
            this.dataLoading = false;
            this.dataLoaded = true;
            this.initInputors();
          });
        };

      if (this.cachedData != null) {
        this.dataLoading = false;
        this.dataLoaded = true;
        this.initInputors();
      }
    }

    fetchData(dataSource) {
      return $.getJSON(dataSource);
    }
  }

  GitLab.GfmAutoComplete = new GfmFactory();

  function mymatcher(text) {
    return text === 'hello';
  }
  function mycallback(text) {
    console.log("GOT SOME TEXT", text);
  }

  $(() => {
    GitLab.GfmAutoComplete.subscribe(mymatcher, mycallback );
  });



}).call(this);
