import { parsePikadayDate } from '~/lib/utils/datefix';

export default class SidebarStore {
  constructor({
    startDateIsFixed,
    startDateFromMilestones,
    startDate,
    dueDateIsFixed,
    dueDateFromMilestones,
    endDate,
    subscribed,
    todoExists,
    todoDeletePath,
  }) {
    this.startDateIsFixed = startDateIsFixed;
    this.startDateFromMilestones = startDateFromMilestones;
    this.startDate = startDate;
    this.dueDateIsFixed = dueDateIsFixed;
    this.dueDateFromMilestones = dueDateFromMilestones;
    this.endDate = endDate;
    this.subscribed = subscribed;
    this.todoExists = todoExists;
    this.todoDeletePath = todoDeletePath;
  }

  get startDateTime() {
    return this.startDate ? parsePikadayDate(this.startDate) : null;
  }

  get startDateTimeFromMilestones() {
    return this.startDateFromMilestones ? parsePikadayDate(this.startDateFromMilestones) : null;
  }

  get endDateTime() {
    return this.endDate ? parsePikadayDate(this.endDate) : null;
  }

  get dueDateTimeFromMilestones() {
    return this.dueDateFromMilestones ? parsePikadayDate(this.dueDateFromMilestones) : null;
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
