import { bisectDate } from '../utils/date_time_formatters';

const mixins = {
  methods: {
    mouseOverDeployInfo(mouseXPos) {
      if (!this.reducedDeploymentData) return false;

      let dataFound = false;
      this.reducedDeploymentData = this.reducedDeploymentData.map((d) => {
        const deployment = d;
        console.log(d.xPos)
        console.log(mouseXPos)
        if (d.xPos >= mouseXPos - 10 && d.xPos <= mouseXPos + 10 && !dataFound) {
          dataFound = d.xPos + 1;

          deployment.showDeploymentFlag = true;
        } else {
          deployment.showDeploymentFlag = false;
        }
        return deployment;
      });

      return dataFound;
    },

    formatDeployments() {
      this.reducedDeploymentData = this.deploymentData.reduce((deploymentDataArray, deployment) => {
        const time = new Date(deployment.created_at);
        const xPos = Math.floor(this.activeTimeSeries[1].timeSeriesScaleX(time));

        time.setSeconds(this.activeTimeSeries[1].values[0].time.getSeconds());

        console.log(xPos)

        if (xPos >= 0) {
          const seriesIndex = bisectDate(this.timeSeries[0].values, time);

          deploymentDataArray.push({
            id: deployment.id,
            time,
            sha: deployment.sha,
            commitUrl: `${this.projectPath}/commit/${deployment.sha}`,
            tag: deployment.tag,
            tagUrl: deployment.tag ? `${this.tagsPath}/${deployment.ref.name}` : null,
            ref: deployment.ref.name,
            xPos,
            seriesIndex,
            showDeploymentFlag: false,
          });
        }

        return deploymentDataArray;
      }, []);
    },

    positionFlag() {
      const timeSeries = this.timeSeries[0]
      // .find(series => {
      //   if (!series) return;
      //   const hoveredDataIndex = bisectDate(series.values, this.hoverData.hoveredDate);
      //   const currentData = timeSeries.values[hoveredDataIndex]
      //   return currentData
      // });

      if (!timeSeries) return;
      const hoveredDataIndex = bisectDate(timeSeries.values, this.hoverData.hoveredDate);

      this.currentData = timeSeries.values[hoveredDataIndex] || {};
      if (!this.currentData || !timeSeries) {
        return;
      }
      this.currentXCoordinate = Math.floor(timeSeries.timeSeriesScaleX(this.currentData.time));

      let val

      this.currentCoordinates = this.activeTimeSeries
        .filter((series) => {
          const currentDataIndex = bisectDate(series.values, this.hoverData.hoveredDate);
          const currentData = series.values[currentDataIndex];
          if  (!currentData) { debugger; return null; }
          const currentX = Math.floor(series.timeSeriesScaleX(currentData.time));
          const currentY = Math.floor(series.timeSeriesScaleY(currentData.value));

          // if hovered data doesn't match we don't want this
          if (currentData.time == this.hoverData.hoveredDate) {
            return true
          } else {
            console.log('neg')
            return  false;
          }
        })
        .map((series) => {
          const currentDataIndex = bisectDate(series.values, this.hoverData.hoveredDate);
          const currentData = series.values[currentDataIndex];
          if  (!currentData) { debugger; return null; }
          const currentX = Math.floor(series.timeSeriesScaleX(currentData.time));
          const currentY = Math.floor(series.timeSeriesScaleY(currentData.value));

          return {
            currentX,
            currentY,
            currentDataIndex,
          };
      });

      if (this.hoverData.currentDeployXPos) {
        this.showFlag = false;
      } else {
        this.showFlag = true;
      }
    },
  },
};

export default mixins;
