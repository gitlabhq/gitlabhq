import { parsePikadayDate } from '~/lib/utils/datefix';

export default class SidebarStore {
  constructor({ startDate, endDate, subscribed, todoExists, todoDeletePath }) {
    this.startDate = startDate;
    this.endDate = endDate;
    this.subscribed = subscribed;
    this.todoExists = todoExists;
    this.todoDeletePath = todoDeletePath;
  }

  get startDateTime() {
    return this.startDate ? parsePikadayDate(this.startDate) : null;
  }

  get endDateTime() {
    return this.endDate ? parsePikadayDate(this.endDate) : null;
  }

  setSubscribed(subscribed) {
    this.subscribed = subscribed;
  }

  setTodoExists(todoExists) {
    this.todoExists = todoExists;
  }

  setTodoDeletePath(deletePath) {
    this.todoDeletePath = deletePath;
  }
}
