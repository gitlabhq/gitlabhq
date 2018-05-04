import { parsePikadayDate } from '~/lib/utils/datefix';

export default class SidebarStore {
  constructor({ startDate, endDate, subscribed }) {
    this.startDate = startDate;
    this.endDate = endDate;
    this.subscribed = subscribed;
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
}
