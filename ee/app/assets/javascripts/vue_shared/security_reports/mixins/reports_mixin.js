import {
  LOADING,
  ERROR,
  SUCCESS,
} from '../store/constants';

export default {
  methods: {
    checkReportStatus(loading, error) {
      if (loading) {
        return LOADING;
      } else if (error) {
        return ERROR;
      }

      return SUCCESS;
    },
  },
};
