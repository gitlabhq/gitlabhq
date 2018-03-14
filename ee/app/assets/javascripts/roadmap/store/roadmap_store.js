import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { parsePikadayDate } from '~/lib/utils/datefix';

export default class RoadmapStore {
  constructor(groupId, timeframe) {
    this.state = {};
    this.state.epics = [];
    this.state.currentGroupId = groupId;
    this.state.timeframe = timeframe;

    this.firstTimeframeItem = this.state.timeframe[0];

    this.lastTimeframeItem = this.state.timeframe[this.state.timeframe.length - 1];
  }

  setEpics(epics) {
    this.state.epics = epics.map(
      epic => RoadmapStore.formatEpicDetails(epic, this.firstTimeframeItem, this.lastTimeframeItem),
    );
  }

  getEpics() {
    return this.state.epics;
  }

  getCurrentGroupId() {
    return this.state.currentGroupId;
  }

  getTimeframe() {
    return this.state.timeframe;
  }

  /**
   * This method constructs Epic object and assigns proxy dates
   * in case start or end dates are unavailable.
   *
   * @param {Object} rawEpic
   * @param {Date} firstTimeframeItem
   * @param {Date} lastTimeframeItem
   */
  static formatEpicDetails(rawEpic, firstTimeframeItem, lastTimeframeItem) {
    const epicItem = convertObjectPropsToCamelCase(rawEpic);

    if (rawEpic.start_date) {
      // If startDate is present
      const startDate = parsePikadayDate(rawEpic.start_date);

      if (startDate <= firstTimeframeItem) {
        // If startDate is less than first timeframe item
        // startDate is out of range;
        epicItem.startDateOutOfRange = true;
        // store original start date in different object
        epicItem.originalStartDate = startDate;
        // Use startDate object to set a proxy date so
        // that timeline bar can render it.
        epicItem.startDate = new Date(firstTimeframeItem.getTime());
      } else {
        // startDate is within timeframe range
        epicItem.startDate = startDate;
      }
    } else {
      // Start date is not available
      epicItem.startDateUndefined = true;
      // Set proxy date so that timeline bar can render it.
      epicItem.startDate = new Date(firstTimeframeItem.getTime());
    }

    // Same as above but for endDate
    // This entire chunk can be moved into generic method
    // but we're keeping it here for the sake of simplicity.
    if (rawEpic.end_date) {
      const endDate = parsePikadayDate(rawEpic.end_date);
      if (endDate >= lastTimeframeItem) {
        epicItem.endDateOutOfRange = true;
        epicItem.originalEndDate = endDate;
        epicItem.endDate = new Date(lastTimeframeItem.getTime());
      } else {
        epicItem.endDate = endDate;
      }
    } else {
      epicItem.endDateUndefined = true;
      epicItem.endDate = new Date(lastTimeframeItem.getTime());
    }

    return epicItem;
  }
}
