# frozen_string_literal: true

FactoryBot.define do
  factory :issue_customer_relations_contact, class: 'CustomerRelations::IssueContact' do
    issue { association(:issue, project: project) }
    contact { association(:contact, group: group) }

    transient do
      group { association(:group) }
      project { association(:project, group: group) }
    end

    trait :for_contact do
      issue { association(:issue, project: project) }
      contact { raise ArgumentError, '`contact` is manadatory' }

      transient do
        project { association(:project, group: contact.group) }
      end
    end

    trait :for_issue do
      issue { raise ArgumentError, '`issue` is manadatory' }
      contact { association(:contact, group: issue.project.root_ancestor) }
    end
  end
end
