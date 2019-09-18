import * as badgeHelper from './badge_helper';
import * as commentIndicatorHelper from './comment_indicator_helper';
import * as domHelper from './dom_helper';
import * as utilsHelper from './utils_helper';

export default {
  addCommentIndicator: commentIndicatorHelper.addCommentIndicator,
  removeCommentIndicator: commentIndicatorHelper.removeCommentIndicator,
  showCommentIndicator: commentIndicatorHelper.showCommentIndicator,
  commentIndicatorOnClick: commentIndicatorHelper.commentIndicatorOnClick,

  addImageBadge: badgeHelper.addImageBadge,
  addImageCommentBadge: badgeHelper.addImageCommentBadge,
  addAvatarBadge: badgeHelper.addAvatarBadge,

  setPositionDataAttribute: domHelper.setPositionDataAttribute,
  updateDiscussionAvatarBadgeNumber: domHelper.updateDiscussionAvatarBadgeNumber,
  updateDiscussionBadgeNumber: domHelper.updateDiscussionBadgeNumber,
  toggleCollapsed: domHelper.toggleCollapsed,

  resizeCoordinatesToImageElement: utilsHelper.resizeCoordinatesToImageElement,
  generateBadgeFromDiscussionDOM: utilsHelper.generateBadgeFromDiscussionDOM,
  getTargetSelection: utilsHelper.getTargetSelection,
};
