import Chart from 'chart.js';
import initGroupMemberContributions from 'ee/group_member_contributions';

document.addEventListener('DOMContentLoaded', () => {
  const dataEl = document.getElementById('js-analytics-data');
  if (dataEl) {
    const data = JSON.parse(dataEl.innerHTML);
    const labels = data.labels;
    const outputElIds = ['push', 'issues_closed', 'merge_requests_created'];

    outputElIds.forEach((id) => {
      const el = document.getElementById(id);
      const ctx = el.getContext('2d');
      const chart = new Chart(ctx);

      chart.Bar({
        labels,
        datasets: [{
          fillColor: 'rgba(220,220,220,0.5)',
          strokeColor: 'rgba(220,220,220,1)',
          barStrokeWidth: 1,
          barValueSpacing: 1,
          barDatasetSpacing: 1,
          data: data[id].data,
        }],
      },
        {
          scaleOverlay: true,
          responsive: true,
          maintainAspectRatio: false,
        },
      );
    });

    initGroupMemberContributions();
  }
});
