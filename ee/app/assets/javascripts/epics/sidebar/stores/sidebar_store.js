import { parsePikadayDate } from '~/lib/utils/datefix';

export default class SidebarStore {
  constructor({ startDate, endDate }) {
    this.startDate = startDate;
    this.endDate = endDate;
  }

  get startDateTime() {
    return this.startDate ? parsePikadayDate(this.startDate) : null;
  }

  get endDateTime() {
    return this.endDate ? parsePikadayDate(this.endDate) : null;
  }
}
