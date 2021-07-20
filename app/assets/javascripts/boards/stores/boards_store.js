/* eslint-disable no-shadow, no-param-reassign,consistent-return */
/* global List */
/* global ListIssue */
import { sortBy } from 'lodash';
import Vue from 'vue';
import BoardsStoreEE from 'ee_else_ce/boards/stores/boards_store_ee';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createDefaultClient from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
// eslint-disable-next-line import/no-deprecated
import { mergeUrlParams, urlParamsToObject, getUrlParamsArray } from '~/lib/utils/url_utility';
import { ListType, flashAnimationDuration } from '../constants';
import eventHub from '../eventhub';
import ListAssignee from '../models/assignee';
import ListLabel from '../models/label';
import ListMilestone from '../models/milestone';
import IssueProject from '../models/project';

const PER_PAGE = 20;
export const gqlClient = createDefaultClient();

const boardsStore = {
  disabled: false,
  timeTracking: {
    limitToHours: false,
  },
  scopedLabels: {
    enabled: false,
  },
  filter: {
    path: '',
  },
  state: {
    currentBoard: {
      labels: [],
    },
    currentPage: '',
    endpoints: {},
  },
  detail: {
    issue: {},
    list: {},
  },
  moving: {
    issue: {},
    list: {},
  },
  multiSelect: { list: [] },

  setEndpoints({
    boardsEndpoint,
    listsEndpoint,
    bulkUpdatePath,
    boardId,
    recentBoardsEndpoint,
    fullPath,
  }) {
    const listsEndpointGenerate = `${listsEndpoint}/generate.json`;
    this.state.endpoints = {
      boardsEndpoint,
      boardId,
      listsEndpoint,
      listsEndpointGenerate,
      bulkUpdatePath,
      fullPath,
      recentBoardsEndpoint: `${recentBoardsEndpoint}.json`,
    };
  },
  create() {
    this.state.lists = [];
    this.filter.path = getUrlParamsArray().join('&');
    this.detail = {
      issue: {},
      list: {},
    };
  },
  showPage(page) {
    this.state.currentPage = page;
  },
  updateListPosition(listObj) {
    const listType = listObj.listType || listObj.list_type;
    let { position } = listObj;
    if (listType === ListType.closed) {
      position = Infinity;
    } else if (listType === ListType.backlog) {
      position = -1;
    }

    const list = new List({ ...listObj, position });
    return list;
  },
  addList(listObj) {
    const list = this.updateListPosition(listObj);
    this.state.lists = sortBy([...this.state.lists, list], 'position');
    return list;
  },
  new(listObj) {
    const list = this.addList(listObj);
    const backlogList = this.findList('type', 'backlog');

    list
      .save()
      .then(() => {
        list.highlighted = true;
        setTimeout(() => {
          list.highlighted = false;
        }, flashAnimationDuration);

        // Remove any new issues from the backlog
        // as they will be visible in the new list
        list.issues.forEach(backlogList.removeIssue.bind(backlogList));
        this.state.lists = sortBy(this.state.lists, 'position');
      })
      .catch(() => {
        // https://gitlab.com/gitlab-org/gitlab-foss/issues/30821
      });
  },

  updateNewListDropdown(listId) {
    document
      .querySelector(`.js-board-list-${getIdFromGraphQLId(listId)}`)
      ?.classList.remove('is-active');
  },

  findIssueLabel(issue, findLabel) {
    return issue.labels.find((label) => label.id === findLabel.id);
  },

  goToNextPage(list) {
    if (list.issuesSize > list.issues.length) {
      if (list.issues.length / PER_PAGE >= 1) {
        list.page += 1;
      }

      return list.getIssues(false);
    }
  },

  addListIssue(list, issue, listFrom, newIndex) {
    let moveBeforeId = null;
    let moveAfterId = null;

    if (!list.findIssue(issue.id)) {
      if (newIndex !== undefined) {
        list.issues.splice(newIndex, 0, issue);

        if (list.issues[newIndex - 1]) {
          moveBeforeId = list.issues[newIndex - 1].id;
        }

        if (list.issues[newIndex + 1]) {
          moveAfterId = list.issues[newIndex + 1].id;
        }
      } else {
        list.issues.push(issue);
      }

      if (list.label) {
        issue.addLabel(list.label);
      }

      if (list.assignee) {
        if (listFrom && listFrom.type === 'assignee') {
          issue.removeAssignee(listFrom.assignee);
        }
        issue.addAssignee(list.assignee);
      }

      if (IS_EE && list.milestone) {
        if (listFrom && listFrom.type === 'milestone') {
          issue.removeMilestone(listFrom.milestone);
        }
        issue.addMilestone(list.milestone);
      }

      if (listFrom) {
        list.issuesSize += 1;

        list.updateIssueLabel(issue, listFrom, moveBeforeId, moveAfterId);
      }
    }
  },
  findListIssue(list, id) {
    return list.issues.find((issue) => issue.id === id);
  },

  removeList(id) {
    const list = this.findList('id', id);

    if (!list) return;

    this.state.lists = this.state.lists.filter((list) => list.id !== id);
  },
  moveList(listFrom, orderLists) {
    orderLists.forEach((id, i) => {
      const list = this.findList('id', parseInt(id, 10));

      list.position = i;
    });
    listFrom.update();
  },

  addMultipleListIssues(list, issues, listFrom, newIndex) {
    let moveBeforeId = null;
    let moveAfterId = null;

    const listHasIssues = issues.every((issue) => list.findIssue(issue.id));

    if (!listHasIssues) {
      if (newIndex !== undefined) {
        if (list.issues[newIndex - 1]) {
          moveBeforeId = list.issues[newIndex - 1].id;
        }

        if (list.issues[newIndex]) {
          moveAfterId = list.issues[newIndex].id;
        }

        list.issues.splice(newIndex, 0, ...issues);
      } else {
        list.issues.push(...issues);
      }

      if (list.label) {
        issues.forEach((issue) => issue.addLabel(list.label));
      }

      if (list.assignee) {
        if (listFrom && listFrom.type === 'assignee') {
          issues.forEach((issue) => issue.removeAssignee(listFrom.assignee));
        }
        issues.forEach((issue) => issue.addAssignee(list.assignee));
      }

      if (IS_EE && list.milestone) {
        if (listFrom && listFrom.type === 'milestone') {
          issues.forEach((issue) => issue.removeMilestone(listFrom.milestone));
        }
        issues.forEach((issue) => issue.addMilestone(list.milestone));
      }

      if (listFrom) {
        list.issuesSize += issues.length;

        list.updateMultipleIssues(issues, listFrom, moveBeforeId, moveAfterId);
      }
    }
  },

  removeListIssues(list, removeIssue) {
    list.issues = list.issues.filter((issue) => {
      const matchesRemove = removeIssue.id === issue.id;

      if (matchesRemove) {
        list.issuesSize -= 1;
        issue.removeLabel(list.label);
      }

      return !matchesRemove;
    });
  },
  removeListMultipleIssues(list, removeIssues) {
    const ids = removeIssues.map((issue) => issue.id);

    list.issues = list.issues.filter((issue) => {
      const matchesRemove = ids.includes(issue.id);

      if (matchesRemove) {
        list.issuesSize -= 1;
        issue.removeLabel(list.label);
      }

      return !matchesRemove;
    });
  },

  startMoving(list, issue) {
    Object.assign(this.moving, { list, issue });
  },

  onNewListIssueResponse(list, issue, data) {
    issue.refreshData(data);

    if (list.issues.length > 1) {
      const moveBeforeId = list.issues[1].id;
      this.moveIssue(issue.id, null, null, null, moveBeforeId);
    }
  },

  moveMultipleIssuesToList({ listFrom, listTo, issues, newIndex }) {
    const issueTo = issues.map((issue) => listTo.findIssue(issue.id));
    const issueLists = issues.map((issue) => issue.getLists()).flat();
    const listLabels = issueLists.map((list) => list.label);
    const hasMoveableIssues = issueTo.filter(Boolean).length > 0;

    if (!hasMoveableIssues) {
      // Check if target list assignee is already present in this issue
      if (
        listTo.type === ListType.assignee &&
        listFrom.type === ListType.assignee &&
        issues.some((issue) => issue.findAssignee(listTo.assignee))
      ) {
        const targetIssues = issues.map((issue) => listTo.findIssue(issue.id));
        targetIssues.forEach((targetIssue) => targetIssue.removeAssignee(listFrom.assignee));
      } else if (listTo.type === 'milestone') {
        const currentMilestones = issues.map((issue) => issue.milestone);
        const currentLists = this.state.lists
          .filter((list) => list.type === 'milestone' && list.id !== listTo.id)
          .filter((list) =>
            list.issues.some((listIssue) => issues.some((issue) => listIssue.id === issue.id)),
          );

        issues.forEach((issue) => {
          currentMilestones.forEach((milestone) => {
            issue.removeMilestone(milestone);
          });
        });

        issues.forEach((issue) => {
          issue.addMilestone(listTo.milestone);
        });

        currentLists.forEach((currentList) => {
          issues.forEach((issue) => {
            currentList.removeIssue(issue);
          });
        });

        listTo.addMultipleIssues(issues, listFrom, newIndex);
      } else {
        // Add to new lists issues if it doesn't already exist
        listTo.addMultipleIssues(issues, listFrom, newIndex);
      }
    } else {
      listTo.updateMultipleIssues(issues, listFrom);
      issues.forEach((issue) => {
        issue.removeLabel(listFrom.label);
      });
    }

    if (listTo.type === ListType.closed && listFrom.type !== ListType.backlog) {
      issueLists.forEach((list) => {
        issues.forEach((issue) => {
          list.removeIssue(issue);
        });
      });

      issues.forEach((issue) => {
        issue.removeLabels(listLabels);
      });
    } else if (listTo.type === ListType.backlog && listFrom.type === ListType.assignee) {
      issues.forEach((issue) => {
        issue.removeAssignee(listFrom.assignee);
      });
      issueLists.forEach((list) => {
        issues.forEach((issue) => {
          list.removeIssue(issue);
        });
      });
    } else if (listTo.type === ListType.backlog && listFrom.type === ListType.milestone) {
      issues.forEach((issue) => {
        issue.removeMilestone(listFrom.milestone);
      });
      issueLists.forEach((list) => {
        issues.forEach((issue) => {
          list.removeIssue(issue);
        });
      });
    } else if (
      this.shouldRemoveIssue(listFrom, listTo) &&
      this.issuesAreContiguous(listFrom, issues)
    ) {
      listFrom.removeMultipleIssues(issues);
    }
  },

  issuesAreContiguous(list, issues) {
    // When there's only 1 issue selected, we can return early.
    if (issues.length === 1) return true;

    // Create list of ids for issues involved.
    const listIssueIds = list.issues.map((issue) => issue.id);
    const movedIssueIds = issues.map((issue) => issue.id);

    // Check if moved issue IDs is sub-array
    // of source list issue IDs (i.e. contiguous selection).
    return listIssueIds.join('|').includes(movedIssueIds.join('|'));
  },

  moveIssueToList(listFrom, listTo, issue, newIndex) {
    const issueTo = listTo.findIssue(issue.id);
    const issueLists = issue.getLists();
    const listLabels = issueLists.map((listIssue) => listIssue.label);

    if (!issueTo) {
      // Check if target list assignee is already present in this issue
      if (
        listTo.type === 'assignee' &&
        listFrom.type === 'assignee' &&
        issue.findAssignee(listTo.assignee)
      ) {
        const targetIssue = listTo.findIssue(issue.id);
        targetIssue.removeAssignee(listFrom.assignee);
      } else if (listTo.type === 'milestone') {
        const currentMilestone = issue.milestone;
        const currentLists = this.state.lists
          .filter((list) => list.type === 'milestone' && list.id !== listTo.id)
          .filter((list) => list.issues.some((listIssue) => issue.id === listIssue.id));

        issue.removeMilestone(currentMilestone);
        issue.addMilestone(listTo.milestone);
        currentLists.forEach((currentList) => currentList.removeIssue(issue));
        listTo.addIssue(issue, listFrom, newIndex);
      } else {
        // Add to new lists issues if it doesn't already exist
        listTo.addIssue(issue, listFrom, newIndex);
      }
    } else {
      listTo.updateIssueLabel(issue, listFrom);
      issueTo.removeLabel(listFrom.label);
    }

    if (listTo.type === 'closed' && listFrom.type !== 'backlog') {
      issueLists.forEach((list) => {
        list.removeIssue(issue);
      });
      issue.removeLabels(listLabels);
    } else if (listTo.type === 'backlog' && listFrom.type === 'assignee') {
      issue.removeAssignee(listFrom.assignee);
      listFrom.removeIssue(issue);
    } else if (listTo.type === 'backlog' && listFrom.type === 'milestone') {
      issue.removeMilestone(listFrom.milestone);
      listFrom.removeIssue(issue);
    } else if (this.shouldRemoveIssue(listFrom, listTo)) {
      listFrom.removeIssue(issue);
    }
  },
  shouldRemoveIssue(listFrom, listTo) {
    return (
      (listTo.type !== 'label' && listFrom.type === 'assignee') ||
      (listTo.type !== 'assignee' && listFrom.type === 'label') ||
      listFrom.type === 'backlog' ||
      listFrom.type === 'closed'
    );
  },
  moveIssueInList(list, issue, oldIndex, newIndex, idArray) {
    const beforeId = parseInt(idArray[newIndex - 1], 10) || null;
    const afterId = parseInt(idArray[newIndex + 1], 10) || null;

    list.moveIssue(issue, oldIndex, newIndex, beforeId, afterId);
  },
  moveMultipleIssuesInList({ list, issues, oldIndicies, newIndex, idArray }) {
    const beforeId = parseInt(idArray[newIndex - 1], 10) || null;
    const afterId = parseInt(idArray[newIndex + issues.length], 10) || null;
    list.moveMultipleIssues({
      issues,
      oldIndicies,
      newIndex,
      moveBeforeId: beforeId,
      moveAfterId: afterId,
    });
  },
  findList(key, val) {
    return this.state.lists.find((list) => list[key] === val);
  },
  findListByLabelId(id) {
    return this.state.lists.find((list) => list.type === 'label' && list.label.id === id);
  },

  toggleFilter(filter) {
    const filterPath = this.filter.path.split('&');
    const filterIndex = filterPath.indexOf(filter);

    if (filterIndex === -1) {
      filterPath.push(filter);
    } else {
      filterPath.splice(filterIndex, 1);
    }

    this.filter.path = filterPath.join('&');

    this.updateFiltersUrl();

    eventHub.$emit('updateTokens');
  },

  setListDetail(newList) {
    this.detail.list = newList;
  },

  updateFiltersUrl() {
    window.history.pushState(null, null, `?${this.filter.path}`);
  },

  clearDetailIssue() {
    this.setIssueDetail({});
  },

  setIssueDetail(issueDetail) {
    this.detail.issue = issueDetail;
  },

  setTimeTrackingLimitToHours(limitToHours) {
    this.timeTracking.limitToHours = parseBoolean(limitToHours);
  },

  generateBoardGid(boardId) {
    return `gid://gitlab/Board/${boardId}`;
  },

  generateBoardsPath(id) {
    return `${this.state.endpoints.boardsEndpoint}${id ? `/${id}` : ''}.json`;
  },

  generateIssuesPath(id) {
    return `${this.state.endpoints.listsEndpoint}${id ? `/${id}` : ''}/issues`;
  },

  generateIssuePath(boardId, id) {
    return `${gon.relative_url_root}/-/boards/${boardId ? `${boardId}` : ''}/issues${
      id ? `/${id}` : ''
    }`;
  },

  generateMultiDragPath(boardId) {
    return `${gon.relative_url_root}/-/boards/${boardId ? `${boardId}` : ''}/issues/bulk_move`;
  },

  all() {
    return axios.get(this.state.endpoints.listsEndpoint);
  },

  createList(entityId, entityType) {
    const list = {
      [entityType]: entityId,
    };

    return axios.post(this.state.endpoints.listsEndpoint, {
      list,
    });
  },

  updateList(id, position, collapsed) {
    return axios.put(`${this.state.endpoints.listsEndpoint}/${id}`, {
      list: {
        position,
        collapsed,
      },
    });
  },

  updateListFunc(list) {
    const collapsed = !list.isExpanded;
    return this.updateList(list.id, list.position, collapsed).catch(() => {
      // TODO: handle request error
    });
  },

  destroyList(id) {
    return axios.delete(`${this.state.endpoints.listsEndpoint}/${id}`);
  },
  destroy(list) {
    const index = this.state.lists.indexOf(list);
    this.state.lists.splice(index, 1);
    this.updateNewListDropdown(list.id);

    this.destroyList(list.id).catch(() => {
      // TODO: handle request error
    });
  },

  saveList(list) {
    const entity = list.label || list.assignee || list.milestone || list.iteration;
    let entityType = '';
    if (list.label) {
      entityType = 'label_id';
    } else if (list.assignee) {
      entityType = 'assignee_id';
    } else if (IS_EE && list.milestone) {
      entityType = 'milestone_id';
    } else if (IS_EE && list.iteration) {
      entityType = 'iteration_id';
    }

    return this.createList(entity.id, entityType)
      .then((res) => res.data)
      .then((data) => {
        list.id = data.id;
        list.type = data.list_type;
        list.position = data.position;
        list.label = data.label;

        return list.getIssues();
      });
  },

  getListIssues(list, emptyIssues = true) {
    const data = {
      // eslint-disable-next-line import/no-deprecated
      ...urlParamsToObject(this.filter.path),
      page: list.page,
    };

    if (list.label && data.label_name) {
      data.label_name = data.label_name.filter((label) => label !== list.label.title);
    }

    if (emptyIssues) {
      list.loading = true;
    }

    return this.getIssuesForList(list.id, data)
      .then((res) => res.data)
      .then((data) => {
        list.loading = false;
        list.issuesSize = data.size;

        if (emptyIssues) {
          list.issues = [];
        }

        data.issues.forEach((issueObj) => {
          list.addIssue(new ListIssue(issueObj));
        });

        return data;
      });
  },

  getIssuesForList(id, filter = {}) {
    const data = { id };
    Object.keys(filter).forEach((key) => {
      data[key] = filter[key];
    });

    return axios.get(mergeUrlParams(data, this.generateIssuesPath(id)));
  },

  moveIssue(id, fromListId = null, toListId = null, moveBeforeId = null, moveAfterId = null) {
    return axios.put(this.generateIssuePath(this.state.endpoints.boardId, id), {
      from_list_id: fromListId,
      to_list_id: toListId,
      move_before_id: moveBeforeId,
      move_after_id: moveAfterId,
    });
  },

  moveListIssues(list, issue, oldIndex, newIndex, moveBeforeId, moveAfterId) {
    list.issues.splice(oldIndex, 1);
    list.issues.splice(newIndex, 0, issue);

    this.moveIssue(issue.id, null, null, moveBeforeId, moveAfterId).catch(() => {
      // TODO: handle request error
    });
  },

  moveMultipleIssues({ ids, fromListId, toListId, moveBeforeId, moveAfterId }) {
    return axios.put(this.generateMultiDragPath(this.state.endpoints.boardId), {
      from_list_id: fromListId,
      to_list_id: toListId,
      move_before_id: moveBeforeId,
      move_after_id: moveAfterId,
      ids,
    });
  },

  moveListMultipleIssues({ list, issues, oldIndicies, newIndex, moveBeforeId, moveAfterId }) {
    oldIndicies.reverse().forEach((index) => {
      list.issues.splice(index, 1);
    });
    list.issues.splice(newIndex, 0, ...issues);

    return this.moveMultipleIssues({
      ids: issues.map((issue) => issue.id),
      fromListId: null,
      toListId: null,
      moveBeforeId,
      moveAfterId,
    });
  },

  newIssue(id, issue) {
    if (typeof id === 'string') {
      id = getIdFromGraphQLId(id);
    }

    return axios.post(this.generateIssuesPath(id), {
      issue,
    });
  },

  newListIssue(list, issue) {
    list.addIssue(issue, null, 0);
    list.issuesSize += 1;
    let listId = list.id;
    if (typeof listId === 'string') {
      listId = getIdFromGraphQLId(listId);
    }

    return this.newIssue(list.id, issue)
      .then((res) => res.data)
      .then((data) => list.onNewIssueResponse(issue, data));
  },

  getBacklog(data) {
    return axios.get(
      mergeUrlParams(
        data,
        `${gon.relative_url_root}/-/boards/${this.state.endpoints.boardId}/issues.json`,
      ),
    );
  },
  removeIssueLabel(issue, removeLabel) {
    if (removeLabel) {
      issue.labels = issue.labels.filter((label) => removeLabel.id !== label.id);
    }
  },

  addIssueAssignee(issue, assignee) {
    if (!issue.findAssignee(assignee)) {
      issue.assignees.push(new ListAssignee(assignee));
    }
  },

  setIssueAssignees(issue, assignees) {
    issue.assignees = [...assignees];
  },

  removeIssueLabels(issue, labels) {
    labels.forEach(issue.removeLabel.bind(issue));
  },

  bulkUpdate(issueIds, extraData = {}) {
    const data = {
      update: Object.assign(extraData, {
        issuable_ids: issueIds.join(','),
      }),
    };

    return axios.post(this.state.endpoints.bulkUpdatePath, data);
  },

  getIssueInfo(endpoint) {
    return axios.get(endpoint);
  },

  toggleIssueSubscription(endpoint) {
    return axios.post(endpoint);
  },

  recentBoards() {
    return axios.get(this.state.endpoints.recentBoardsEndpoint);
  },

  setCurrentBoard(board) {
    this.state.currentBoard = board;
  },

  toggleMultiSelect(issue) {
    const selectedIssueIds = this.multiSelect.list.map((issue) => issue.id);
    const index = selectedIssueIds.indexOf(issue.id);

    if (index === -1) {
      this.multiSelect.list.push(issue);
      return;
    }

    this.multiSelect.list = [
      ...this.multiSelect.list.slice(0, index),
      ...this.multiSelect.list.slice(index + 1),
    ];
  },
  removeIssueAssignee(issue, removeAssignee) {
    if (removeAssignee) {
      issue.assignees = issue.assignees.filter((assignee) => assignee.id !== removeAssignee.id);
    }
  },

  findIssueAssignee(issue, findAssignee) {
    return issue.assignees.find((assignee) => assignee.id === findAssignee.id);
  },

  clearMultiSelect() {
    this.multiSelect.list = [];
  },

  removeAllIssueAssignees(issue) {
    issue.assignees = [];
  },

  addIssueMilestone(issue, milestone) {
    const miletoneId = issue.milestone ? issue.milestone.id : null;
    if (IS_EE && milestone.id !== miletoneId) {
      issue.milestone = new ListMilestone(milestone);
    }
  },

  setIssueLoadingState(issue, key, value) {
    issue.isLoading[key] = value;
  },

  updateIssueData(issue, newData) {
    Object.assign(issue, newData);
  },

  setIssueFetchingState(issue, key, value) {
    issue.isFetching[key] = value;
  },

  removeIssueMilestone(issue, removeMilestone) {
    if (IS_EE && removeMilestone && removeMilestone.id === issue.milestone.id) {
      issue.milestone = {};
    }
  },

  refreshIssueData(issue, obj) {
    const convertedObj = convertObjectPropsToCamelCase(obj, {
      dropKeys: ['issue_sidebar_endpoint', 'real_path', 'webUrl'],
    });
    convertedObj.sidebarInfoEndpoint = obj.issue_sidebar_endpoint;
    issue.path = obj.real_path || obj.webUrl;
    issue.project_id = obj.project_id;
    Object.assign(issue, convertedObj);

    if (obj.project) {
      issue.project = new IssueProject(obj.project);
    }

    if (obj.milestone) {
      issue.milestone = new ListMilestone(obj.milestone);
      issue.milestone_id = obj.milestone.id;
    }

    if (obj.labels) {
      issue.labels = obj.labels.map((label) => new ListLabel(label));
    }

    if (obj.assignees) {
      issue.assignees = obj.assignees.map((a) => new ListAssignee(a));
    }
  },
  addIssueLabel(issue, label) {
    if (!issue.findLabel(label)) {
      issue.labels.push(new ListLabel(label));
    }
  },
  updateIssue(issue) {
    const data = {
      issue: {
        milestone_id: issue.milestone ? issue.milestone.id : null,
        due_date: issue.dueDate,
        assignee_ids: issue.assignees.length > 0 ? issue.assignees.map(({ id }) => id) : [0],
        label_ids: issue.labels.length > 0 ? issue.labels.map(({ id }) => id) : [''],
      },
    };

    return axios.patch(`${issue.path}.json`, data).then(({ data: body = {} } = {}) => {
      /**
       * Since post implementation of Scoped labels, server can reject
       * same key-ed labels. To keep the UI and server Model consistent,
       * we're just assigning labels that server echo's back to us when we
       * PATCH the said object.
       */
      if (body) {
        issue.labels = convertObjectPropsToCamelCase(body.labels, { deep: true });
      }
    });
  },
};

BoardsStoreEE.initEESpecific(boardsStore);

// hacks added in order to allow milestone_select to function properly
// TODO: remove these

export function boardStoreIssueSet(...args) {
  Vue.set(boardsStore.detail.issue, ...args);
}

export function boardStoreIssueDelete(...args) {
  Vue.delete(boardsStore.detail.issue, ...args);
}

export default boardsStore;
