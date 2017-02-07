/* eslint-disable no-param-reassign */
((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  const EMPTY_STAGE_TEXTS = {
    issue: 'The issue stage shows the time it takes from creating an issue to assigning the issue to a milestone, or add the issue to a list on your Issue Board. Begin creating issues to see data for this stage.',
    plan: 'The planning stage shows the time from the previous step to pushing your first commit. This time will be added automatically once you push your first commit.',
    code: 'The coding stage shows the time from the first commit to creating the merge request. The data will automatically be added here once you create your first merge request.',
    test: 'The testing stage shows the time GitLab CI takes to run every pipeline for the related merge request. The data will automatically be added after your first pipeline finishes running.',
    review: 'The review stage shows the time from creating the merge request to merging it. The data will automatically be added after you merge your first merge request.',
    staging: 'The staging stage shows the time between merging the MR and deploying code to the production environment. The data will be automatically added once you deploy to production for the first time.',
    production: 'The production stage shows the total time it takes between creating an issue and deploying the code to production. The data will be automatically added once you have completed the full idea to production cycle.',
  };

  global.cycleAnalytics.CycleAnalyticsStore = {
    state: {
      summary: '',
      stats: '',
      analytics: '',
      events: [],
      stages: [],
    },
    setCycleAnalyticsData(data) {
      this.state = Object.assign(this.state, this.decorateData(data));
    },
    decorateData(data) {
      const newData = {};

      newData.stages = data.stats || [];
      newData.summary = data.summary || [];

      newData.summary.forEach((item) => {
        item.value = item.value || '-';
      });

      newData.stages.forEach((item) => {
        const stageName = item.title.toLowerCase();
        item.active = false;
        item.isUserAllowed = data.permissions[stageName];
        item.emptyStageText = EMPTY_STAGE_TEXTS[stageName];
        item.component = `stage-${stageName}-component`;
      });
      newData.analytics = data;
      return newData;
    },
    setLoadingState(state) {
      this.state.isLoading = state;
    },
    setErrorState(state) {
      this.state.hasError = state;
    },
    deactivateAllStages() {
      this.state.stages.forEach((stage) => {
        stage.active = false;
      });
    },
    setActiveStage(stage) {
      this.deactivateAllStages();
      stage.active = true;
    },
    setStageEvents(events) {
      this.state.events = this.decorateEvents(events);
    },
    decorateEvents(events) {
      const newEvents = [];

      events.forEach((item) => {
        if (!item) return;

        item.totalTime = item.total_time;
        item.author.webUrl = item.author.web_url;
        item.author.avatarUrl = item.author.avatar_url;

        if (item.created_at) item.createdAt = item.created_at;
        if (item.short_sha) item.shortSha = item.short_sha;
        if (item.commit_url) item.commitUrl = item.commit_url;

        delete item.author.web_url;
        delete item.author.avatar_url;
        delete item.total_time;
        delete item.created_at;
        delete item.short_sha;
        delete item.commit_url;

        newEvents.push(item);
      });

      return newEvents;
    },
    currentActiveStage() {
      return this.state.stages.find(stage => stage.active);
    },
  };
})(window.gl || (window.gl = {}));
