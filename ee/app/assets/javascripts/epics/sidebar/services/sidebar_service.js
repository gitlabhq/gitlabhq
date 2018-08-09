import axios from '~/lib/utils/axios_utils';

export default class SidebarService {
  constructor({ endpoint, subscriptionEndpoint, todoPath }) {
    this.endpoint = endpoint;
    this.subscriptionEndpoint = subscriptionEndpoint;
    this.todoPath = todoPath;
  }

  updateStartDate({ dateValue, isFixed }) {
    const requestBody = {
      start_date_is_fixed: isFixed,
    };

    if (isFixed) {
      requestBody.start_date_fixed = dateValue;
    }

    return axios.put(this.endpoint, requestBody);
  }

  updateEndDate({ dateValue, isFixed }) {
    const requestBody = {
      due_date_is_fixed: isFixed,
    };

    if (isFixed) {
      requestBody.due_date_fixed = dateValue;
    }

    return axios.put(this.endpoint, requestBody);
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
