import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { parsePikadayDate } from '~/lib/utils/datefix';

import { PRESET_TYPES } from '../constants';

export default class RoadmapStore {
  constructor(groupId, timeframe, presetType) {
    this.state = {};
    this.state.epics = [];
    this.state.currentGroupId = groupId;
    this.state.timeframe = timeframe;

    this.presetType = presetType;
    this.initTimeframeThreshold();
  }

  initTimeframeThreshold() {
    const lastTimeframeIndex = this.state.timeframe.length - 1;
    if (this.presetType === PRESET_TYPES.QUARTERS) {
      this.timeframeStartDate = this.state.timeframe[0].range[0];
      this.timeframeEndDate = this.state.timeframe[lastTimeframeIndex].range[2];
    } else if (this.presetType === PRESET_TYPES.MONTHS) {
      this.timeframeStartDate = this.state.timeframe[0];
      this.timeframeEndDate = this.state.timeframe[lastTimeframeIndex];
    } else if (this.presetType === PRESET_TYPES.WEEKS) {
      this.timeframeStartDate = this.state.timeframe[0];
      this.timeframeEndDate = new Date(this.state.timeframe[lastTimeframeIndex].getTime());
      this.timeframeEndDate.setDate(this.timeframeEndDate.getDate() + 7);
    }
  }

  setEpics(epics) {
    this.state.epics = epics.map(
      epic => RoadmapStore.formatEpicDetails(epic, this.timeframeStartDate, this.timeframeEndDate),
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
   * @param {Date} timeframeStartDate
   * @param {Date} timeframeEndDate
   */
  static formatEpicDetails(rawEpic, timeframeStartDate, timeframeEndDate) {
    const epicItem = convertObjectPropsToCamelCase(rawEpic);

    if (rawEpic.start_date) {
      // If startDate is present
      const startDate = parsePikadayDate(rawEpic.start_date);

      if (startDate <= timeframeStartDate) {
        // If startDate is less than first timeframe item
        // startDate is out of range;
        epicItem.startDateOutOfRange = true;
        // store original start date in different object
        epicItem.originalStartDate = startDate;
        // Use startDate object to set a proxy date so
        // that timeline bar can render it.
        epicItem.startDate = new Date(timeframeStartDate.getTime());
      } else {
        // startDate is within timeframe range
        epicItem.startDate = startDate;
      }
    } else {
      // Start date is not available
      epicItem.startDateUndefined = true;
      // Set proxy date so that timeline bar can render it.
      epicItem.startDate = new Date(timeframeStartDate.getTime());
    }

    // Same as above but for endDate
    // This entire chunk can be moved into generic method
    // but we're keeping it here for the sake of simplicity.
    if (rawEpic.end_date) {
      const endDate = parsePikadayDate(rawEpic.end_date);
      if (endDate >= timeframeEndDate) {
        epicItem.endDateOutOfRange = true;
        epicItem.originalEndDate = endDate;
        epicItem.endDate = new Date(timeframeEndDate.getTime());
      } else {
        epicItem.endDate = endDate;
      }
    } else {
      epicItem.endDateUndefined = true;
      epicItem.endDate = new Date(timeframeEndDate.getTime());
    }

    return epicItem;
  }
}
