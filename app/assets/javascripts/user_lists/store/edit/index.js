import { defineStore } from 'pinia';
import Api from '~/api';
import { visitUrl } from '~/lib/utils/url_utility';
import statuses from '../../constants/edit';
import { getErrorMessages } from '../utils';

export const useEditUserList = defineStore('editUserList', {
  state: () => ({
    status: statuses.LOADING,
    projectId: '',
    userListIid: '',
    userList: null,
    errorMessage: [],
  }),
  actions: {
    async fetchUserList() {
      this.status = statuses.LOADING;
      try {
        const { data } = await Api.fetchFeatureFlagUserList(this.projectId, this.userListIid);
        this.status = statuses.SUCCESS;
        this.userList = data;
      } catch (error) {
        this.status = statuses.ERROR;
        this.errorMessage = getErrorMessages(error);
      }
    },
    dismissErrorAlert() {
      this.status = statuses.UNSYNCED;
    },
    async updateUserList(userList) {
      try {
        const { data } = await Api.updateFeatureFlagUserList(this.projectId, {
          iid: userList.iid,
          name: userList.name,
        });
        visitUrl(data.path);
      } catch (error) {
        this.status = statuses.ERROR;
        this.errorMessage = getErrorMessages(error);
      }
    },
  },
});
