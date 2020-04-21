---
type: reference, concepts
---

# Availability

GitLab offers a number of options to manage availability and resiliency. Below are the options to consider with trade-offs.

| Event | GitLab Feature | Recovery Point Objective (RPO) | Recovery Time Objective (RTO) | Cost |
| ----- | -------------- | --- | --- | ---- |
| Availability Zone failure | "GitLab HA" | No loss | No loss | 2x Git storage, multiple nodes balanced across AZ's |
| Region failure | [GitLab Geo Disaster Recovery](../geo/disaster_recovery/index.md) | 5-10 minutes | 30 minutes | 2x primary cost |
| All failures | Backup/Restore | Last backup | Hours to Days | Cost of storing the backups |
