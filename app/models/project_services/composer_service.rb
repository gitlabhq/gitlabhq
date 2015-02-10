# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

require 'digest/crc32'

class ComposerService < Service

  prop_accessor :package_mode, :package_type, :export_branches, :branch_filters,
                :export_tags, :tag_filters, :custom_json

  validates :package_mode, :package_type, presence: true, if: :activated?
  validates :custom_json,
    presence: true,
    if: ->(service) { service.activated? && service.package_mode == 'advanced' }

  validates_each :custom_json,
    if: :allow_custom_json_validation? do |record, attr, value|
      begin

        name_re = /([A-Za-z0-9&_-]+\/[A-Za-z0-9&_-]+)/

        if value.empty?
          record.errors.add(attr, 'must be specified')
        elsif (cjson = ActiveSupport::JSON.decode(value))
          if cjson.empty?
            record.errors.add(attr, 'must not be empty')
          elsif not cjson['name']
            record.errors.add(attr, 'must have a name key specified')
          elsif cjson['name'].empty?
            record.errors.add(attr, 'name key must not be empty')
          elsif cjson['name'] != (name_re.match(cjson['name']) || [])[0]
            record.errors.add(attr, 'name key format must be "namespace/project"')
          elsif not cjson['description']
            record.errors.add(attr, 'must have a description key specified')
          elsif cjson['description'].empty?
            record.errors.add(attr, 'description key must not be empty')
          end
        end

      rescue
        record.errors.add(attr, 'must be a valid JSON string')
      end
    end

  after_save :process_packages_on_save

  def allow_custom_json_validation?
    activated? && package_mode == 'advanced'
  end

  def title
    'Composer'
  end

  def description
    'This project will be publicly listed as a composer package, '\
    'but usage of private and internal repositories will still '\
    'require authentication.'
  end

  def help
    if package_mode == 'default'
      'The package is exported using the project\'s composer.json. '\
      'Additional settings are ignored.'
    elsif package_mode == 'project'
      'The package is exported using the project\'s attributes '\
      'The following settings are applied.'
    elsif package_mode == 'advanced'
      'The package is exported using the custom json specified '\
      'in the configuration.'
    end
  end

  def to_param
    'composer'
  end

  def fields
    [
      { type: 'select',
        name: 'package_mode',
        label: 'Package Mode',
        choices:
        [
          ['Built-in: parse composer.json (default)', 'default'],
          ['Project: generate from project attributes', 'project'],
          ['Advanced: use custom JSON', 'advanced']
        ],
        default_choice: 'default'
      },
      { type: 'select',
        name: 'package_type',
        label: 'Package Type',
        hint: 'Applicable only on project package mode.',
        choices:
        [
          ['AGL Module', 'agl-module'],
          ['AnnotateCms Component', 'annotatecms-component'],
          ['AnnotateCms Module', 'annotatecms-module'],
          ['AnnotateCms Service', 'annotatecms-service'],
          ['Asgard Module', 'asgard-module'],
          ['Asgard Theme', 'asgard-theme'],
          ['Bitrix Component', 'bitrix-component'],
          ['Bitrix Module', 'bitrix-module'],
          ['Bitrix Theme', 'bitrix-theme'],
          ['CakePHP 2+ Plugin', 'cakephp-plugin'],
          ['CCFramework Ship', 'ccframework-ship'],
          ['CCFramework Theme', 'ccframework-theme'],
          ['Chef Cookbook', 'chef-cookbook'],
          ['Chef Role', 'chef-role'],
          ['CodeIgniter Library', 'codeigniter-library'],
          ['CodeIgniter Module', 'codeigniter-module'],
          ['CodeIgniter Third Party', 'codeigniter-third-party'],
          ['Composer Library (default)', 'library'],
          ['Composer Meta Package', 'metapackage'],
          ['Composer Plugin', 'composer-plugin'],
          ['Composer Project', 'project'],
          ['Concrete5 Block', 'concrete5-block'],
          ['Concrete5 Package', 'concrete5-package'],
          ['Concrete5 Theme', 'concrete5-theme'],
          ['Concrete5 Update', 'concrete5-update'],
          ['Craft Plugin', 'craft-plugin'],
          ['Croogo Plugin', 'croogo-plugin'],
          ['Croogo Theme', 'croogo-theme'],
          ['DokuWiki Plugin', 'dokuwiki-plugin'],
          ['DokuWiki Template', 'dokuwiki-template'],
          ['Dolibarr Module', 'dolibarr-module'],
          ['Drupal Drush', 'drupal-drush'],
          ['Drupal Library', 'drupal-library'],
          ['Drupal Module', 'drupal-module'],
          ['Drupal Profile', 'drupal-profile'],
          ['Drupal Theme', 'drupal-theme'],
          ['Elgg Plugin', 'elgg-plugin'],
          ['FuelPHP v1.x Module', 'fuel-module'],
          ['FuelPHP v1.x Package', 'fuel-package'],
          ['FuelPHP v1.x Theme', 'fuel-theme'],
          ['FuelPHP v2.x Component', 'fuelphp-component'],
          ['Grav Plugin', 'grav-plugin'],
          ['Grav Theme', 'grav-theme'],
          ['Hurad Plugin', 'hurad-plugin'],
          ['Hurad Theme', 'hurad-theme'],
          ['Joomla Component', 'joomla-component'],
          ['Joomla Library', 'joomla-library'],
          ['Joomla Module', 'joomla-module'],
          ['Joomla Plugin', 'joomla-plugin'],
          ['Joomla Template', 'joomla-template'],
          ['Kirby Plugin', 'kirby-plugin'],
          ['Kohana Module', 'kohana-module'],
          ['Laravel Library', 'laravel-library'],
          ['Lithium Library', 'lithium-library'],
          ['Lithium Source', 'lithium-source'],
          ['Magento Library', 'magento-library'],
          ['Magento Skin', 'magento-skin'],
          ['Magento Theme', 'magento-theme'],
          ['Mako Package', 'mako-package'],
          ['MediaWiki Extension', 'mediawiki-extension'],
          ['MODULEWork Module', 'modulework-module'],
          ['MODX Evo Library', 'modxevo-lib'],
          ['MODX Evo Module', 'modxevo-module'],
          ['MODX Evo Plugin', 'modxevo-plugin'],
          ['MODX Evo Snippet', 'modxevo-snippet'],
          ['MODX Evo Template', 'modxevo-template'],
          ['Moodle Admin Report', 'moodle-admin_report'],
          ['Moodle Assign Feedback', 'moodle-assignfeedback'],
          ['Moodle Assign Submission', 'moodle-assignsubmission'],
          ['Moodle Assignment', 'moodle-assignment'],
          ['Moodle Auth', 'moodle-auth'],
          ['Moodle Availability', 'moodle-availability'],
          ['Moodle Block', 'moodle-block'],
          ['Moodle Calendar Type', 'moodle-calendartype'],
          ['Moodle Course Report', 'moodle-coursereport'],
          ['Moodle Data Field', 'moodle-datafield'],
          ['Moodle Data Preset', 'moodle-datapreset'],
          ['Moodle Editor', 'moodle-editor'],
          ['Moodle Enrol', 'moodle-enrol'],
          ['Moodle Filter', 'moodle-filter'],
          ['Moodle Format', 'moodle-format'],
          ['Moodle Grade Export', 'moodle-gradeexport'],
          ['Moodle Grade Import', 'moodle-gradeimport'],
          ['Moodle Grade Report', 'moodle-gradereport'],
          ['Moodle Grading Form', 'moodle-gradingform'],
          ['Moodle Local', 'moodle-local'],
          ['Moodle Message', 'moodle-message'],
          ['Moodle Mod', 'moodle-mod'],
          ['Moodle Plagiarism', 'moodle-plagiarism'],
          ['Moodle Portfolio', 'moodle-portfolio'],
          ['Moodle Profile Field', 'moodle-profilefield'],
          ['Moodle Question Behaviour', 'moodle-qbehaviour'],
          ['Moodle Question Format', 'moodle-qformat'],
          ['Moodle Question Type', 'moodle-qtype'],
          ['Moodle Quiz Access', 'moodle-quizaccess'],
          ['Moodle Quiz', 'moodle-quiz'],
          ['Moodle Report', 'moodle-report'],
          ['Moodle Repository', 'moodle-repository'],
          ['Moodle Scorm Report', 'moodle-scormreport'],
          ['Moodle Theme', 'moodle-theme'],
          ['Moodle Tool', 'moodle-tool'],
          ['Moodle Web Service', 'moodle-webservice'],
          ['Moodle Workshop Allocation', 'moodle-workshopallocation'],
          ['Moodle Workshop Evaluation', 'moodle-workshopeval'],
          ['Moodle Workshop Form', 'moodle-workshopform'],
          ['October Module', 'october-module'],
          ['October Plugin', 'october-plugin'],
          ['October Theme', 'october-theme'],
          ['OXID Module', 'oxid-module'],
          ['OXID Out', 'oxid-out'],
          ['OXID Theme', 'oxid-theme'],
          ['PhpBB Extension', 'phpbb-extension'],
          ['PhpBB Language', 'phpbb-language'],
          ['PhpBB Style', 'phpbb-style'],
          ['Pimcore Plugin', 'pimcore-plugin'],
          ['Piwik Plugin', 'piwik-plugin'],
          ['PPI Module', 'ppi-module'],
          ['Prestashop: Module', 'prestashop-module'],
          ['Prestashop: Theme', 'prestashop-theme'],
          ['Puppet Module', 'puppet-module'],
          ['REDAXO Addon', 'redaxo-addon'],
          ['Roundcube Plugin', 'roundcube-plugin'],
          ['Shopware Backend Plugin', 'shopware-backend-plugin'],
          ['Shopware Core Plugin', 'shopware-core-plugin'],
          ['Shopware Frontend Plugin', 'shopware-frontend-plugin'],
          ['Shopware Theme', 'shopware-theme'],
          ['SilverStripe Module', 'silverstripe-module'],
          ['SilverStripe Theme', 'silverstripe-theme'],
          ['SMF Module', 'smf-module'],
          ['SMF Theme', 'smf-theme'],
          ['Symfony1 Plugin', 'symfony1-plugin'],
          ['Tusk Asset', 'tusk-asset'],
          ['Tusk Command', 'tusk-command'],
          ['Tusk Task', 'tusk-task'],
          ['TYPO3 CMS Extension', 'typo3-cms-extension'],
          ['TYPO3 Flow Boilerplate', 'typo3-flow-boilerplate'],
          ['TYPO3 Flow Build', 'typo3-flow-build'],
          ['TYPO3 Flow Framework', 'typo3-flow-framework'],
          ['TYPO3 Flow Package', 'typo3-flow-package'],
          ['TYPO3 Flow Plugin', 'typo3-flow-plugin'],
          ['TYPO3 Flow Site', 'typo3-flow-site'],
          ['Wolf CMS Plugin', 'wolfcms-plugin'],
          ['WordPress Core', 'wordpress-core'],
          ['WordPress Must Use Plugin', 'wordpress-muplugin'],
          ['WordPress Plugin', 'wordpress-plugin'],
          ['WordPress Theme', 'wordpress-theme'],
          ['Zend Extra', 'zend-extra'],
          ['Zend Library', 'zend-library'],
          ['Zend Module', 'zend-module'],
          ['Zikula Module', 'zikula-module'],
          ['Zikula Theme', 'zikula-theme']
        ],
        default_choice: 'library'
      },
      { type: 'fieldset', legend: 'Branches:', fields:
        [
          { type: 'checkbox',
            name: 'export_branches',
            label: 'Branch Listing'
          },
          { type: 'text',
            name: 'branch_filters',
            label: 'Branch Filters',
            placeholder: 'branches you wish to export comma seperated.',
            hint: 'Separate branches with commas. '\
                  'Leave blank to export all branches.'
          }
        ]
      },
      { type: 'fieldset', legend: 'Tags:', fields:
        [
          { type: 'checkbox',
            name: 'export_tags',
            label: 'Tag Listing'
          },
          { type: 'text',
            name: 'tag_filters',
            label: 'Tag Filters',
            placeholder: 'tags you wish to export comma seperated.',
            hint: 'Separate tags with commas. '\
                  'Leave blank to export all tags.'
          }
        ]
      },
      { type: 'fieldset', legend: 'Advanced:', fields:
        [
          { type: 'textarea',
            name: 'custom_json',
            label: 'Custom JSON',
            placeholder: 'custom json to use for exporting this package.'
          }
        ]
      }
    ]
  end

  #disable test button
  def can_test?
    false
  end

  def process_packages_on_save

    #process packages for all tags
    project.repository.tags.each do |tag|
      process_commit(tag)
    end

    # process packages for all branches
    project.repository.branches.each do |branch|
      process_commit(branch)
    end
  end

  def process_commit(ref)
    previous_package_removed = false
    begin
      if commit_was_activated? && commit_was_exported?(ref)

        if package_mode_was == 'advanced'
          defaults = ActiveSupport::JSON.decode(custom_json_was)
        else
          defaults = { 'type'=>package_type_was }
        end

        package = Composer::Package.
                    new(project, ref, package_mode_was, defaults)

        manager.rm_package(package)
        previous_package_removed = true

      end
    rescue
      # Skip on error
    end

    begin
      if package_mode == 'advanced'
        defaults = ActiveSupport::JSON.decode(custom_json)
      else
        defaults = { 'type'=>package_type }
      end

      package = Composer::Package.
                  new(project, ref, package_mode, defaults)

      if activated? && commit_is_exported?(ref)
        manager.add_package(package)
      elsif not previous_package_removed
        manager.rm_package(package)
      end

    rescue
      # Skip on error
    end
  end

  def execute(push_data)
    newrev = push_data[:after]
    ref = push_data[:ref]

    # sync our changes
    if newrev == Gitlab::Git::BLANK_SHA # push delete

      # recreate exported packages since we dont have access
      # to the original push
      manager.clear_packages

      #process packages for all tags
      project.repository.tags.each do |t|
        process_commit(t)
      end

      # process packages for all branches
      project.repository.branches.each do |b|
        process_commit(b)
      end

    else # push create / modify
      if push_to_branch?(ref)
        match = project.repository.branches.detect do |b|
          b.name == branch_name(ref) && b.target == newrev
        end
      elsif push_to_tag?(ref)
        match = project.repository.tags.detect do |t|
          t.name == tag_name(ref) && t.target == newrev
        end
      end
      if match
        process_commit(match)
      end
    end

  rescue
    #Skip on error
  end

  private

  def manager
    @manager ||= Composer::Manager.new(project)
  end

  def commit_is_exported?(ref)
    if ref.instance_of?(Gitlab::Git::Branch)
      branch_is_exported?(ref)
    elsif ref.instance_of?(Gitlab::Git::Tag)
      tag_is_exported?(ref)
    else
      false
    end
  end

  def branch_is_exported?(branch)
    if branche_filters
      filters = (branch_filters.strip! || branch_filters).
                  gsub(" ", "").split(',')
    else
      filters = []
    end

    if filters.empty?
      export_branches == '1'
    else
      export_branches == '1' && filters.include?(branch.name)
    end
  end

  def tag_is_exported?(tag)
    if tag_filters
      filters = (tag_filters.strip! || tag_filters).
                  gsub(" ", "").split(',')
    else
      filters = []
    end

    if filters.empty?
      export_tags == '1'
    else
      export_tags == '1' && filters.include?(tag.name)
    end
  end

  def commit_was_activated?
    if active_was == true
      if !activated?
        return true
      elsif package_mode_changed?
        return true
      end
    end
    return false
  end

  def commit_was_exported?(ref)
    if ref.instance_of?(Gitlab::Git::Branch)
      branch_was_exported?(ref)
    elsif ref.instance_of?(Gitlab::Git::Tag)
      tag_was_exported?(ref)
    else
      false
    end
  end

  def branch_was_exported?(branch)
    if branch_filters_was
      filters = (branch_filters_was.strip! || branch_filters_was).
                  gsub(" ", "").split(',')
    else
      filters = []
    end

    if filters.empty?
      export_branches_was == '1'
    else
      export_branches_was == '1' && filters.include?(branch.name)
    end
  end

  def tag_was_exported?(tag)
    if tag_filters_was
      filters = (tag_filters_was.strip! || tag_filters_was).
                  gsub(" ", "").split(',')
    else
      filters = []
    end

    if filters.empty?
      export_tags_was == '1'
    else
      export_tags_was == '1' && filters.include?(tag.name)
    end
  end

  def push_to_branch?(ref)
    ref =~ /refs\/heads/
  end

  def push_to_tag?(ref)
    ref =~ /refs\/tags/
  end

  def ref_name?(ref)
    if push_to_branch?(ref)
      branch_name(ref)
    elsif push_to_tag?(ref)
      tag_name(ref)
    else
      raise 'invalid ref'
    end
  end

  def branch_name(ref)
    ref.gsub('refs/heads/', '')
  end

  def tag_name(ref)
    ref.gsub('refs/tags/', '')
  end
end
