import { PROJECT_BADGE } from '../constants';
import types from './mutation_types';

const reorderBadges = (badges) =>
  badges.sort((a, b) => {
    if (a.kind !== b.kind) {
      return a.kind === PROJECT_BADGE ? 1 : -1;
    }

    return a.id - b.id;
  });

export default {
  [types.RECEIVE_NEW_BADGE](state) {
    Object.assign(state, {
      badgeInAddForm: {},
      isSaving: false,
      renderedBadge: null,
    });
  },
  [types.RECEIVE_NEW_BADGE_ERROR](state) {
    Object.assign(state, {
      isSaving: false,
    });
  },
  [types.REQUEST_NEW_BADGE](state) {
    Object.assign(state, {
      isSaving: true,
    });
  },

  [types.RECEIVE_UPDATED_BADGE](state, updatedBadge) {
    const badges = state.badges.map((badge) => {
      if (badge.id === updatedBadge.id) {
        return updatedBadge;
      }
      return badge;
    });
    Object.assign(state, {
      badgeInEditForm: {},
      badges,
      isEditing: false,
      isSaving: false,
      renderedBadge: null,
    });
  },
  [types.RECEIVE_UPDATED_BADGE_ERROR](state) {
    Object.assign(state, {
      isSaving: false,
    });
  },
  [types.REQUEST_UPDATED_BADGE](state) {
    Object.assign(state, {
      isSaving: true,
    });
  },

  [types.RECEIVE_LOAD_BADGES](state, badges) {
    Object.assign(state, {
      badges: reorderBadges(badges),
      isLoading: false,
    });
  },
  [types.RECEIVE_LOAD_BADGES_ERROR](state) {
    Object.assign(state, {
      isLoading: false,
    });
  },

  [types.REQUEST_LOAD_BADGES](state) {
    Object.assign(state, {
      isLoading: true,
    });
  },

  [types.RECEIVE_DELETE_BADGE_ERROR](state, badgeId) {
    const badges = state.badges.map((badge) => {
      if (badge.id === badgeId) {
        return {
          ...badge,
          isDeleting: false,
        };
      }

      return badge;
    });
    Object.assign(state, {
      badges,
    });
  },
  [types.REQUEST_DELETE_BADGE](state, badgeId) {
    const badges = state.badges.map((badge) => {
      if (badge.id === badgeId) {
        return {
          ...badge,
          isDeleting: true,
        };
      }

      return badge;
    });
    Object.assign(state, {
      badges,
    });
  },

  [types.RECEIVE_RENDERED_BADGE](state, renderedBadge) {
    Object.assign(state, { isRendering: false, renderedBadge });
  },
  [types.RECEIVE_RENDERED_BADGE_ERROR](state) {
    Object.assign(state, { isRendering: false });
  },
  [types.REQUEST_RENDERED_BADGE](state) {
    Object.assign(state, { isRendering: true });
  },

  [types.RECEIVE_PAGINATION](state, pagination) {
    Object.assign(state, {
      pagination,
    });
  },

  [types.START_EDITING](state, badge) {
    Object.assign(state, {
      badgeInEditForm: { ...badge },
      isEditing: true,
      renderedBadge: { ...badge },
    });
  },
  [types.STOP_EDITING](state) {
    Object.assign(state, {
      badgeInEditForm: {},
      isEditing: false,
      renderedBadge: null,
    });
  },

  [types.UPDATE_BADGE_IN_FORM](state, badge) {
    if (state.isEditing) {
      Object.assign(state, {
        badgeInEditForm: badge,
      });
    } else {
      Object.assign(state, {
        badgeInAddForm: badge,
      });
    }
  },

  [types.UPDATE_BADGE_IN_MODAL](state, badge) {
    Object.assign(state, {
      badgeInModal: badge,
    });
  },
};
