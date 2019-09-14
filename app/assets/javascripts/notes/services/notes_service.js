import axios from '~/lib/utils/axios_utils';
import * as constants from '../constants';

export default {
  fetchDiscussions(endpoint, filter, persistFilter = true) {
    const config =
      filter !== undefined
        ? { params: { notes_filter: filter, persist_filter: persistFilter } }
        : null;
    return axios.get(endpoint, config);
  },
  replyToDiscussion(endpoint, data) {
    return axios.post(endpoint, data);
  },
  updateNote(endpoint, data) {
    return axios.put(endpoint, data);
  },
  createNewNote(endpoint, data) {
    return axios.post(endpoint, data);
  },
  toggleResolveNote(endpoint, isResolved) {
    const { RESOLVE_NOTE_METHOD_NAME, UNRESOLVE_NOTE_METHOD_NAME } = constants;
    const method = isResolved ? UNRESOLVE_NOTE_METHOD_NAME : RESOLVE_NOTE_METHOD_NAME;

    return axios[method](endpoint);
  },
  poll(data = {}) {
    const endpoint = data.notesData.notesPath;
    const { lastFetchedAt } = data;
    const options = {
      headers: {
        'X-Last-Fetched-At': lastFetchedAt ? `${lastFetchedAt}` : undefined,
      },
    };

    return axios.get(endpoint, options);
  },
  toggleIssueState(endpoint, data) {
    return axios.put(endpoint, data);
  },
};
