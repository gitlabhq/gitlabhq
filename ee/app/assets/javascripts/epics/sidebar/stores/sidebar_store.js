import { parsePikadayDate } from '~/lib/utils/datefix';

export default class SidebarStore {
  constructor({
    startDateIsFixed,
    startDateFixed,
    startDateFromMilestones,
    startDate,
    dueDateIsFixed,
    dueDateFixed,
    dueDateFromMilestones,
    endDate,
    subscribed,
    todoExists,
    todoDeletePath,
  }) {
    this.startDateIsFixed = startDateIsFixed;
    this.startDateFixed = startDateFixed;
    this.startDateFromMilestones = startDateFromMilestones;
    this.startDate = startDate;
    this.dueDateFixed = dueDateFixed;
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

  get startDateTimeFixed() {
    return this.startDateFixed ? parsePikadayDate(this.startDateFixed) : null;
  }

  get startDateTimeFromMilestones() {
    return this.startDateFromMilestones ? parsePikadayDate(this.startDateFromMilestones) : null;
  }

  get endDateTime() {
    return this.endDate ? parsePikadayDate(this.endDate) : null;
  }

  get dueDateTimeFixed() {
    return this.dueDateFixed ? parsePikadayDate(this.dueDateFixed) : null;
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
