import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default class GroupMemberStore {
  constructor() {
    this.state = {};
    this.state.members = [];
    this.state.columns = [];
    this.state.sortOrders = {};
    this.state.currentSortedColumn = '';
  }

  get members() {
    return this.state.members;
  }

  get sortOrders() {
    return this.state.sortOrders;
  }

  setColumns(columns) {
    this.state.columns = columns;
    this.state.sortOrders = this.state.columns.reduce(
      (acc, column) => ({ ...acc, [column.name]: 1 }),
      {},
    );
  }

  setMembers(rawMembers) {
    this.state.members = rawMembers.map(rawMember => GroupMemberStore.formatMember(rawMember));
  }

  sortMembers(sortByColumn) {
    if (sortByColumn) {
      this.state.currentSortedColumn = sortByColumn;
      this.state.sortOrders[sortByColumn] = this.state.sortOrders[sortByColumn] * -1;

      const currentColumnOrder = this.state.sortOrders[sortByColumn] || 1;
      const members = this.state.members.slice().sort((a, b) => {
        let delta = -1;
        const columnOrderA = a[sortByColumn];
        const columnOrderB = b[sortByColumn];

        if (columnOrderA === columnOrderB) {
          delta = 0;
        } else if (columnOrderA > columnOrderB) {
          delta = 1;
        }

        return delta * currentColumnOrder;
      });

      this.state.members = members;
    }
  }

  static formatMember(rawMember) {
    return convertObjectPropsToCamelCase(rawMember);
  }
}
