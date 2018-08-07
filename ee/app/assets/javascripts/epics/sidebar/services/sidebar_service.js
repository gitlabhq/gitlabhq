import axios from '~/lib/utils/axios_utils';

export default class SidebarService {
  constructor({ endpoint, subscriptionEndpoint, todoPath }) {
    this.endpoint = endpoint;
    this.subscriptionEndpoint = subscriptionEndpoint;
    this.todoPath = todoPath;
  }

  updateStartDate(startDate) {
    return axios.put(this.endpoint, { start_date: startDate });
  }

  updateEndDate(endDate) {
    return axios.put(this.endpoint, { end_date: endDate });
  }

  toggleSubscribed() {
    return axios.post(this.subscriptionEndpoint);
  }

  addTodo(epicId) {
    return axios.post(this.todoPath, {
      issuable_id: epicId,
      issuable_type: 'epic',
    });
  }

  // eslint-disable-next-line class-methods-use-this
  deleteTodo(todoDeletePath) {
    return axios.delete(todoDeletePath);
  }
}
