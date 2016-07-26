((w) => {
  class ResolveServiceClass {
    constructor() {
      const actions = {
        resolve: {
          method: 'POST',
          url: 'notes{/id}/resolve',
        },
        all: {
          method: 'POST',
          url: 'notes/resolve_all',
        }
      };

      this.resource = Vue.resource('notes{/id}', {}, actions);
    }

    setCSRF() {
      Vue.http.headers.common['X-CSRF-Token'] = $.rails.csrfToken();
    }

    resolve(namespace, discussionId, noteId, resolve) {
      this.setCSRF();
      Vue.http.options.root = `/${namespace}`;

      return this.resource
        .resolve({ id: noteId }, { discussion: discussionId, resolved: resolve })
        .then((response) => {
          if (response.status === 200) {
            CommentsStore.update(discussionId, noteId, resolve)
          }
        });
    }

    resolveAll(namespace, discussionId, allResolve) {
      this.setCSRF();
      Vue.http.options.root = `/${namespace}`;

      let ids = []
      for (const noteId in CommentsStore.state[discussionId]) {
        const resolved = CommentsStore.state[discussionId][noteId];

        if (resolved === allResolve) {
          ids.push(noteId);
        }
      }

      CommentsStore.loading[discussionId] = true;
      return this.resource
        .all({}, { ids: ids, discussion: discussionId, resolved: !allResolve })
        .then((response) => {
          if (response.status === 200) {
            for (const noteId in ids) {
              CommentsStore.update(discussionId, noteId, !allResolve);
            }
          }

          CommentsStore.loading[discussionId] = false;
        });
    }
  }

  w.ResolveService = new ResolveServiceClass();
}(window));
